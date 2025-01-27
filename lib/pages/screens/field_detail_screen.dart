import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/BookingDialog%20.dart';

class FieldDetailScreen extends StatefulWidget {
  final Field field;
  FieldDetailScreen({required this.field});
  @override
  _FieldDetailScreenState createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen>
    with SingleTickerProviderStateMixin {
  int _currentImage = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  void _showBookingDialog(Field field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BookingDialog(field: field),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 250,
                    viewportFraction: 1.0,
                    onPageChanged: (index, _) =>
                        setState(() => _currentImage = index),
                    autoPlay: true,
                  ),
                  items: widget.field.images
                          ?.map((url) => CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _buildShimmer(),
                              ))
                          .toList() ??
                      [],
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (widget.field.images ?? [])
                        .asMap()
                        .entries
                        .map((entry) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImage == entry.key
                              ? Colors.white
                              : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Color(0xFF00BFFF),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.field.name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.black),
                          Text(widget.field.location,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Card(
                        elevation: 10, // Agrega un efecto de sombra.
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Precio por partido',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize:
                                          14, // Tamaño de texto más pequeño.
                                    ),
                                  ),
                                  SizedBox(height: 8), // Espaciado entre texto.
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money,
                                          color:
                                              Colors.green), // Icono de precio.
                                      Text(
                                        '${widget.field.price_per_match}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => _showBookingDialog(widget
                                    .field), // usar widget.field en lugar de field
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Reservar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Card(
                    elevation: 8, // Sombra básica
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Bordes redondeados
                    ),
                    margin: EdgeInsets.all(16), // Margen alrededor del Card

                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Horarios Disponibles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.field.available_hours
                                  .map(
                                    (time) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // Acción al presionar el botón
                                          print('Selected time: $time');
                                        },
                                        child: Text(time),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                              color: Colors
                                                  .blue), // Bordes con color azul
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                    child: Container(
                      color: Colors.white,
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Servicios que incluye:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black),
                          ),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            children: widget.field.amenities != null &&
                                    widget.field.amenities!.isNotEmpty
                                ? widget.field.amenities!
                                    .map(
                                      (amenity) => AmenityTile(
                                        icon: _getAmenityIcon(
                                            amenity), // Asigna un icono basado en el servicio
                                        text:
                                            amenity, // Muestra el nombre del servicio
                                      ),
                                    )
                                    .toList()
                                : [
                                    Text('No amenities available')
                                  ], // Si no hay servicios, muestra un mensaje
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Partidos Activos',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      ActiveGameTile(),
                      SizedBox(height: 8),
                      ActiveGameTile(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _getAmenityIcon(String amenity) {
  switch (amenity.toLowerCase()) {
    case 'vestidores':
      return Icons.people;
    case 'seguridad':
      return Icons.shield;
    case '24/7':
      return Icons.access_time;
    case 'estacionamiento':
      return Icons.local_parking;
    default:
      return Icons.help_outline;
  }
}

Widget _buildShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(color: Colors.white),
  );
}

class AmenityTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const AmenityTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
              fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ActiveGameTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Partido Amistoso',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Text('Hoy • 18:00',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          TextButton(
            onPressed: () {},
            child: Text('Unirse', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
