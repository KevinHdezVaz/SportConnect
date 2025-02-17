import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/screens/field_detail_screen.dart';
import 'package:user_auth_crudd10/services/field_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class FieldsScreen extends StatefulWidget {
  @override
  _FieldsScreenState createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen>
    with WidgetsBindingObserver {
  final _fieldService = FieldService();
  List<Field>? fields;
  LatLng _initialPosition = LatLng(19.432608, -99.133209);
  Position? _currentPosition;
  GoogleMapController? _mapController;
  bool _isLocationServiceDialogShown = false;
  BitmapDescriptor _myLocationIcon = BitmapDescriptor.defaultMarker;
  String? _mapStyle;
  PageController _pageController =
      PageController(viewportFraction: 0.8); // Agrega esto

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestLocationPermission();
    _loadFields();
    _getSavedLocation();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    // Cargar el archivo JSON desde los assets
    _mapStyle = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService();
    }
  }

  Set<Marker> _getMarkers() {
    Set<Marker> markers = {};

    if (fields != null) {
      for (var i = 0; i < fields!.length; i++) {
        final field = fields![i];
        markers.add(
          Marker(
            markerId: MarkerId(field.id.toString()),
            position: LatLng(field.latitude!, field.longitude!),
            infoWindow: InfoWindow(
              title: field.name,
              snippet: field.description,
            ),
            onTap: () {
              // Desplaza el PageView a la posición correspondiente
              _pageController.animateToPage(
                i,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        );
      }
    }

    return markers;
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled && _isLocationServiceDialogShown) {
      setState(() {
        _isLocationServiceDialogShown = false;
      });
      _getCurrentLocation();
    }
  }

  Future<void> _getSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');

    if (latitude != null && longitude != null) {
      setState(() {
        _initialPosition = LatLng(latitude, longitude);
      });
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
      if (_currentPosition != null) {
        final loadedFields = await _fieldService.getNearbyFields();
        print('Canchas cercanas: $loadedFields');
        setState(() => fields = loadedFields);
      } else {
        print('Ubicación actual no disponible');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
    });

    _saveCurrentLocation(_initialPosition);

    if (_mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_initialPosition),
      );
    }

    // Cargar canchas cercanas después de obtener la ubicación
    _loadFields();

    return position;
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      print("Permiso concedido");
      _getCurrentLocation();
    } else if (status.isDenied) {
      print("Permiso denegado");
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _showLocationServiceDialog() {
    if (_isLocationServiceDialogShown) return;

    setState(() {
      _isLocationServiceDialogShown = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Servicio de Ubicación Desactivado',
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            'Para continuar, activa el servicio de ubicación.',
            style: TextStyle(color: const Color.fromARGB(255, 48, 47, 47)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLocationServiceDialogShown = false;
                });
              },
              child: Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                openLocationSettings();
              },
              child: Text(
                'Abrir Configuración',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    Future.delayed(Duration(seconds: 1), () {
      _getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: screenHeight * 0.8, // 75% de la altura de la pantalla
              child: GoogleMap(
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  controller.setMapStyle(_mapStyle);
                  if (_currentPosition != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                      ),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 13.0,
                ),
                markers: _getMarkers(),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.25,
              maxChildSize: 0.75,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Barra deslizadora
                      Container(
                        margin: EdgeInsets.only(top: 10, bottom: 10),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),

                      // Lista de canchas
                      Expanded(
                        child: fields == null
                            ? Center(child: CircularProgressIndicator())
                            : NotificationListener<ScrollNotification>(
                                onNotification:
                                    (ScrollNotification notification) {
                                  if (notification is UserScrollNotification &&
                                      notification.direction ==
                                          ScrollDirection.forward) {}
                                  return false;
                                },
                                child: PageView.builder(
                                  controller:
                                      _pageController, // Usa el PageController aquí
                                  itemCount: fields!.length,
                                  itemBuilder: (context, index) {
                                    final field = fields![index];

                                    return Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: _buildVenueCard(
                                        name: field.name,
                                        descripcion: field.description,
                                        distance: '2.5 km',
                                        images: field.images,
                                        address: 'Calle Deportiva 456',
                                        type: field.type,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    FieldDetailScreen(
                                                        field: field)),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildVenueCard({
    required String name,
    required String descripcion,
    required String distance,
    required String address,
    required String type,
    required List<String>? images, // Changed this line
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 300,
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: images?.isNotEmpty == true
                        ? Uri.parse(baseUrl)
                            .replace(path: images!.first)
                            .toString()
                        : 'https://via.placeholder.com/200',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildShimmer(),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      Text(
                        descripcion,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.sports_soccer,
                              size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "Cancha de " + type,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
