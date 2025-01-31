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
 List<String> availableHours = [];  
  bool isLoadingHours = false;

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
        child: ScaffoldMessenger(child: BookingDialog(field: field)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.field == null) {
      return Scaffold(
        body: Center(
          child: Text('No se ha proporcionado información del campo.'),
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de Cancha 1

                    Container(
                      color: Color(0xFF00BFFF),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.field.name ?? 'Nombre no disponible',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.black),
                              Text(
                                widget.field.location ??
                                    'Ubicación no disponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Precio por partido',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.attach_money,
                                              color: Colors.green),
                                          Text(
                                            '${widget.field.price_per_match ?? 'N/A'}',
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
                                    onPressed: () =>
                                        _showBookingDialog(widget.field),
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
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
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

                    SizedBox(height: 40),

                    Stack(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 150,
                            viewportFraction: 0.6,
                            onPageChanged: (index, _) =>
                                setState(() => _currentImage = index),
                            autoPlay: true,
                          ),
                          items: (widget.field.images ?? []).map((url) {
                            return GestureDetector(
                              onTap: () {
                                 showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      child: InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: CachedNetworkImage(
                                          imageUrl: url,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _buildShimmer(),
                              ),
                            );
                          }).toList(),
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
                    SizedBox(height: 20),

                    Container(
                      child: const TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Sobre la cancha'),
                          Tab(text: 'Torneos activos'),
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context)
                          .size
                          .height, // Ocupa toda la altura de la pantalla
                      child: TabBarView(
                        children: [
                          // Contenido de la pestaña "Sobre la cancha"
                          Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(16),
                                child: Card(
                                  elevation: 10,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Localización',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 18),
                                        Text(
                                          'Sótano de la plaza "Puerta del Sol Periférico Sur, 4237"',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black),
                                        ),
                                        SizedBox(height: 8),
                                        Card(
                                          elevation: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.near_me,
                                                    color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text(
                                                  '¿Cómo llegar?',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(16),
                                child: Card(
                                  elevation: 10,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Horario',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'La información de horarios la proporciona el propio establecimiento, si tienes alguna duda ponte en contacto con el establecimiento.',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black),
                                        ),
                                        SizedBox(height: 8),
                                        Table(
                                          border: TableBorder.all(
                                              color: Colors.grey),
                                          children: [
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text('Lunes',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                      '06:00 a 10:30 y 17:30 a 21:30'),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text('Martes',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                      '06:00 a 10:30 y 17:30 a 21:30'),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text('Miércoles',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                      '06:00 a 10:30 y 17:30 a 21:30'),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text('Jueves',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                      '06:00 a 10:30 y 17:30 a 21:30'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Contenido de la pestaña "Torneos activos"
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Lista de torneos activos...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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