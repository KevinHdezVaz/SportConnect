import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/screens/field_detail_screen.dart';
import 'package:user_auth_crudd10/services/field_service.dart';

class FieldsScreen extends StatefulWidget {
  @override
  _FieldsScreenState createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  final _fieldService = FieldService();
  List<Field>? fields;
  LatLng _initialPosition = LatLng(19.432608, -99.133209);
  Position? _currentPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadFields();
    _getSavedLocation();
  }

  Future<void> _getSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');

    if (latitude != null && longitude != null) {
      setState(() {
        _initialPosition = LatLng(latitude, longitude);
      });
      // Only animate camera if _mapController is not null
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_initialPosition),
      );
    }
  }

  Future<void> _saveCurrentLocation(LatLng position) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('latitude', position.latitude);
    prefs.setDouble('longitude', position.longitude);
  }

  Future<void> _loadFields() async {
    try {
      print('Solicitando canchas...');
      final loadedFields = await _fieldService.getFields();
      print('Respuesta: $loadedFields');
      setState(() => fields = loadedFields);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si el servicio de ubicación está desactivado, muestra un mensaje o solicita activarlo
      _showLocationServiceDialog();
      return Future.error('El servicio de ubicación está desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado');
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
    });

    // Guardar la ubicación actual
    _saveCurrentLocation(_initialPosition);

    // Mover la cámara solo si _mapController está inicializado
    if (_mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_initialPosition),
      );
    }

    return position;
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      print("Permiso concedido");
      _getCurrentLocation(); // Obtener ubicación solo después de que el permiso sea concedido
    } else if (status.isDenied) {
      print("Permiso denegado");
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // Si es denegado permanentemente, abrir la configuración de la app
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Servicio de Ubicación Desactivado'),
          content: Text('Para continuar, activa el servicio de ubicación.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                openLocationSettings();
              },
              child: Text('Abrir Configuración'),
            ),
          ],
        );
      },
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    Future.delayed(Duration(seconds: 1), () {
      _getCurrentLocation(); // Recarga la ubicación después de abrir los ajustes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Search Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.search, color: Colors.grey),
                          ),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Buscar canchas, jugadores o equipos',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Map Section
            Container(
              height: 250,
              color: Colors.grey[300],
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // Aquí puedes mover la cámara después de que se haya creado el mapa
                  if (_currentPosition != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude)),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('current_location'),
                    position: _initialPosition,
                    infoWindow: InfoWindow(title: 'Tu Ubicación'),
                  ),
                },
              ),
            ),

            Expanded(
              child: fields == null
                  ? const Center(
                      child: CircularProgressIndicator()) // Indicador de carga
                  : ListView.builder(
                      itemCount: fields!.length,
                      itemBuilder: (context, index) {
                        final field = fields![index];
                        return _buildVenueCard(
                          name: field.name,
                          descripcion: field.description,
                          rating: 4.5,
                          distance: '2.5 km',
                          address: 'Calle Deportiva 456',
                          activeGames: 5,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      FieldDetailScreen(field: field)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Venue Card Widget
  Widget _buildVenueCard({
    required String name,
    required String descripcion,
    required double rating,
    required String distance,
    required String address,
    required int activeGames,
    required VoidCallback onPressed,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                /*
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(color: Colors.yellow),
                    ),
                  ],
                ),
                */
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$descripcion',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Distance and Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$distance • $address',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Active Games and Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$activeGames partidos activos',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver Detalles',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
