import 'package:flutter/material.dart';
import 'package:uwefrenchaymaps/secret_key.dart'; // Stores the Google Maps API Key
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:label_marker/label_marker.dart';

import 'dart:math' show cos, sqrt, asin;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UWE Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  CameraPosition _initialLocation =
      CameraPosition(target: LatLng(51.5023, -2.5469));
  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.89,
      height: 50,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white70,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
            borderSide: BorderSide(
              color: Colors.greenAccent.shade200,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      // Use the retrieved coordinates of the current position,
      // instead of the address if the start position is user's
      // current position, as it results in better accuracy.
      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : startPlacemark[0].latitude;

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : startPlacemark[0].longitude;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      // Start Location Marker
      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Destination Location Marker
      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Adding the markers to the list
      markers.add(startMarker);
      markers.add(destinationMarker);

      markers
          .addLabelMarker(LabelMarker(
        label: "A",
        markerId: MarkerId("Ablock"),
        position: LatLng(51.49933604129863, -2.5473945844650996),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "B",
        markerId: MarkerId("Bblock"),
        position: LatLng(51.49894380901779, -2.5480912190349003),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "C",
        markerId: MarkerId("Cblock"),
        position: LatLng(51.49947565916752, -2.5482416303646365),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "D",
        markerId: MarkerId("Dblock"),
        position: LatLng(51.50001808592639, -2.5483690091012723),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "E",
        markerId: MarkerId("Eblock"),
        position: LatLng(51.500415963927516, -2.548256603990805),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "F",
        markerId: MarkerId("Fblock"),
        position: LatLng(51.50032525179908, -2.5476620323729042),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "G",
        markerId: MarkerId("Gblock"),
        position: LatLng(51.50023561068161, -2.5469502159056288),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "H",
        markerId: MarkerId("Hblock"),
        position: LatLng(51.49997242079033, -2.546906964248796),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "J",
        markerId: MarkerId("Jblock"),
        position: LatLng(51.499786733685056, -2.5464183028393483),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "K",
        markerId: MarkerId("Kblock"),
        position: LatLng(51.49967484391101, -2.5469934914901953),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "L",
        markerId: MarkerId("Lblock"),
        position: LatLng(51.49965738077651, -2.547519473254706),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "M",
        markerId: MarkerId("Mblock"),
        position: LatLng(51.50053847997679, -2.547106112554106),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "N",
        markerId: MarkerId("Nblock"),
        position: LatLng(51.500865361999985, -2.547086243627545),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "P",
        markerId: MarkerId("Pblock"),
        position: LatLng(51.50112949028888, -2.5493190545636035),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "Q",
        markerId: MarkerId("Qblock"),
        position: LatLng(51.500958444534554, -2.5482354911411145),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "Q",
        markerId: MarkerId("Qblock2"),
        position: LatLng(51.5018319430442, -2.548748099906706),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "R",
        markerId: MarkerId("Rblock"),
        position: LatLng(51.502537819854695, -2.548781397836527),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "S",
        markerId: MarkerId("Sblock"),
        position: LatLng(51.49782752194857, -2.5481758218496826),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );
      markers
          .addLabelMarker(LabelMarker(
        label: "T",
        markerId: MarkerId("Tblock"),
        position: LatLng(51.501624727626826, -2.5520239250454897),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "U (Student Union)",
        markerId: MarkerId("UBlock"),
        position: LatLng(51.50056504211304, -2.551526571003834),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );
      markers
          .addLabelMarker(LabelMarker(
        label: "W",
        markerId: MarkerId("Wblock"),
        position: LatLng(51.50065792373229, -2.5526900285761545),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );
      markers
          .addLabelMarker(LabelMarker(
        label: "Bristol Business School (X)",
        markerId: MarkerId("Xblock"),
        position: LatLng(51.500789121338414, -2.5497931042109565),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "Z",
        markerId: MarkerId("Zblock"),
        position: LatLng(51.50043352343438, -2.5499241848095235),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      markers
          .addLabelMarker(LabelMarker(
        label: "School of Engineering",
        markerId: MarkerId("Z2"),
        position: LatLng(51.50006661766683, -2.5502449446375195),
        backgroundColor: Colors.green,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      // Calculating to check that the position relative to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the camera view of the map
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );

      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude);

      double totalDistance = 0.0;

      //calculate the total distance
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
        print('DISTANCE: $_placeDistance km');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Formula to calculate distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      secretKey.API_KEY, // contains Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.transit,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.lightGreenAccent,
      points: polylineCoordinates,
      width: 6,
    );
    polylines[id] = polyline;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.hybrid,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) async {
                mapController = controller;
                Position position = await _determinePosition();
                mapController.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 17)));
                markers
                    .addLabelMarker(LabelMarker(
                  label: "A",
                  markerId: MarkerId("A"),
                  position: LatLng(51.49933604129863, -2.5473945844650996),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "B",
                  markerId: MarkerId("B"),
                  position: LatLng(51.49894380901779, -2.5480912190349003),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "C",
                  markerId: MarkerId("C"),
                  position: LatLng(51.49947565916752, -2.5482416303646365),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "D",
                  markerId: MarkerId("D"),
                  position: LatLng(51.50001808592639, -2.5483690091012723),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "E",
                  markerId: MarkerId("E"),
                  position: LatLng(51.500415963927516, -2.548256603990805),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "F",
                  markerId: MarkerId("F"),
                  position: LatLng(51.50032525179908, -2.5476620323729042),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "G",
                  markerId: MarkerId("G"),
                  position: LatLng(51.50023561068161, -2.5469502159056288),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "H",
                  markerId: MarkerId("H"),
                  position: LatLng(51.49997242079033, -2.546906964248796),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "J",
                  markerId: MarkerId("J"),
                  position: LatLng(51.499786733685056, -2.5464183028393483),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "K",
                  markerId: MarkerId("K"),
                  position: LatLng(51.49967484391101, -2.5469934914901953),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "L",
                  markerId: MarkerId("L"),
                  position: LatLng(51.49965738077651, -2.547519473254706),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "M",
                  markerId: MarkerId("M"),
                  position: LatLng(51.50053847997679, -2.547106112554106),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "N",
                  markerId: MarkerId("N"),
                  position: LatLng(51.500865361999985, -2.547086243627545),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "P",
                  markerId: MarkerId("P"),
                  position: LatLng(51.50112949028888, -2.5493190545636035),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "Q",
                  markerId: MarkerId("Qblok"),
                  position: LatLng(51.500958444534554, -2.5482354911411145),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "Q",
                  markerId: MarkerId("Qblok2"),
                  position: LatLng(51.5018319430442, -2.548748099906706),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "R",
                  markerId: MarkerId("Rblok"),
                  position: LatLng(51.502537819854695, -2.548781397836527),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "S",
                  markerId: MarkerId("Sblok"),
                  position: LatLng(51.49782752194857, -2.5481758218496826),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );
                markers
                    .addLabelMarker(LabelMarker(
                  label: "T",
                  markerId: MarkerId("T"),
                  position: LatLng(51.501624727626826, -2.5520239250454897),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "U (Student Union)",
                  markerId: MarkerId("UBlok"),
                  position: LatLng(51.50056504211304, -2.551526571003834),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );
                markers
                    .addLabelMarker(LabelMarker(
                  label: "W",
                  markerId: MarkerId("Wblok"),
                  position: LatLng(51.50065792373229, -2.5526900285761545),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );
                markers
                    .addLabelMarker(LabelMarker(
                  label: "Bristol Business School (X)",
                  markerId: MarkerId("Xblok"),
                  position: LatLng(51.500789121338414, -2.5497931042109565),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "Z",
                  markerId: MarkerId("Zblok"),
                  position: LatLng(51.50043352343438, -2.5499241848095235),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );

                markers
                    .addLabelMarker(LabelMarker(
                  label: "School of Engineering",
                  markerId: MarkerId("ZSOE"),
                  position: LatLng(51.50006661766683, -2.5502449446375195),
                  backgroundColor: Colors.green,
                ))
                    .then(
                  (value) {
                    setState(() {});
                  },
                );
              },
            ),

            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.white, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    ClipOval(
                      child: Material(
                        color: Colors.white, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Show the place input fields & button for
            // showing the route
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                    ),
                    width: width * 0.98,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image(
                            image: NetworkImage(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/UWE_Bristol_logo.svg/1280px-UWE_Bristol_logo.svg.png'),
                            height: 55,
                            width: 120,
                            alignment: Alignment.topCenter,
                          ),
                          //Text(
                          // 'UWE Maps',
                          // style:
                          //    TextStyle(fontSize: 20.0, color: Colors.white),
                          // ),
                          SizedBox(height: 8),
                          _textField(
                              label: 'Starting point',
                              hint: 'Your Location',
                              prefixIcon: Icon(Icons.location_on),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.my_location),
                                onPressed: () async {
                                  Position position =
                                      await _determinePosition();
                                  mapController.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                              target: LatLng(position.latitude,
                                                  position.longitude),
                                              zoom: 17)));

                                  setState(() {});

                                  startAddressController.text = _currentAddress;
                                  _startAddress = _currentAddress;
                                },
                              ),
                              controller: startAddressController,
                              focusNode: startAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _startAddress = value;
                                });
                              }),
                          SizedBox(height: 10),
                          _textField(
                              label: 'Destination',
                              hint: 'Choose Destination',
                              prefixIcon: Icon(Icons.add_location_sharp),
                              controller: destinationAddressController,
                              focusNode: destinationAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _destinationAddress = value;
                                });
                              }),
                          SizedBox(height: 5),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              ' $_placeDistance km away.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          SizedBox(height: 1), //on pressed find the block
                          ElevatedButton(
                            onPressed: (_startAddress != '' &&
                                    _destinationAddress != '')
                                ? () async {
                                    startAddressFocusNode.unfocus();
                                    destinationAddressFocusNode.unfocus();

                                    setState(() {
                                      if (markers.isNotEmpty) markers.clear();
                                      if (polylines.isNotEmpty)
                                        polylines.clear();
                                      if (polylineCoordinates.isNotEmpty)
                                        polylineCoordinates.clear();
                                      _placeDistance = null;
                                    });

                                    _calculateDistance().then((isCalculated) {
                                      if (isCalculated) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '$_placeDistance km away. Use caution-walking directions may not always reflect real-world conditions.'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error Calculating Distance'),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Find the Block'.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Show current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 40.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.white, // button color
                      child: InkWell(
                        splashColor: Colors.blue, // inkwell color
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();

    return position;
  }
}
