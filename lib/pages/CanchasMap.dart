import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:user_auth_crudd10/model/field.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  List<Field> fields = [];
  bool _isMapLoading = true; // Estado para controlar si el mapa está cargando

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          _currentPosition == null
              ? const Center(child: const CircularProgressIndicator())
              : Stack(
                  children: [
                    GoogleMap(
                       initialCameraPosition: CameraPosition(
                        target: LatLng(
                            _currentPosition!.latitude, _currentPosition!.longitude),
                        zoom: 14,
                      ),
                      onMapCreated: (controller) {
                        _controller.complete(controller);
                        setState(() {
                          _isMapLoading = false; // El mapa se ha cargado
                        });
                      },
                      myLocationEnabled: true,
                    ),
                    if (_isMapLoading)
                      Center(
                        child: CircularProgressIndicator(), // Indicador de carga
                      ),
                  ],
                ),

          // Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar canchas',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: () {
                      // Show filters
                    },
                  ),
                ],
              ),
            ),
          ),

          // Fields List
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: fields.length,
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    return FieldCard(field: field);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

Future<void> _getCurrentLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition();
    print("Current Position: $position");
    setState(() => _currentPosition = position);
    if (_currentPosition != null) {
      _getNearbyFields();
    } else {
      print("Current position is null");
    }
  } catch (e) {
    print("Error getting location: $e");
  }
}

Future<void> _getNearbyFields() async {
  print("Getting nearby fields...");
  Fluttertoast.showToast(
    msg: 'Por favor selecciona una fecha válida',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red,
    textColor: Colors.white,
  );
}
}


class FieldCard extends StatelessWidget {
  final Field field;

  const FieldCard({required this.field});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  field.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    Text(field.description.toString()),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16),
              //  Text(' ${field..toStringAsFixed(1)} km'),
                Spacer(),
               // Text('${field.activeGames} partidos activos'),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Navigate to field details
              },
              child: Text('Ver detalles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

 