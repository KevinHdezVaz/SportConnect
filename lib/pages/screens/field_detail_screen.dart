import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/BookingDialog%20.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

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
  late Field currentField;
  final _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    currentField = widget.field;
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
        child: ScaffoldMessenger(
          child: BookingDialog(
            field: field,
            onBookingComplete: () {
              _refreshFieldData(); // Actualizar los datos cuando se complete la reserva
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshFieldData() async {
    try {
      final updatedField =
          await _bookingService.getFieldDetails(currentField.id);
      setState(() {
        currentField = updatedField;
      });
    } catch (e) {
      print('Error refreshing field data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentField == null) {
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
          body: Column(
            children: [
               Container(
                color: Color(0xFF00BFFF),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ 
                    Text(
                      currentField.name ?? 'Nombre no disponible',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.black),
                        Expanded(
                          child: Text(
                            currentField.municipio ?? 'Ubicación no disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      '${currentField.price_per_match ?? 'N/A'}',
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
                              onPressed: () => _showBookingDialog(currentField),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Reservar',
                                      style: TextStyle(color: Colors.white)),
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

              // Carrusel de imágenes
              Stack(
                children: [
                  // En el CarouselSlider de tu FieldDetailScreen
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 150,
                      viewportFraction: 0.6,
                      onPageChanged: (index, _) =>
                          setState(() => _currentImage = index),
                      autoPlay: true,
                    ),
                    items: (widget.field.images ?? []).map((url) {
                      final fullImageUrl =
                          Uri.parse(baseUrl).replace(path: url).toString();

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
                                    imageUrl:
                                        fullImageUrl,  
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        _buildShimmer(),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: fullImageUrl, // Usar la URL completa
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildShimmer(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
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
                      children: (currentField.images ?? [])
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

              // TabBar
              TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Sobre la cancha'),
                  Tab(text: 'Torneos activos'),
                ],
              ),

              // Contenido scrolleable
              Expanded(
                child: TabBarView(
                  children: [
                    // Primera pestaña: Sobre la cancha
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(16),
                            child: Card(
                              elevation: 10,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Localización',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 18),
                                    Text(
                                      currentField.municipio ??
                                          'Ubicación no disponible',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                    SizedBox(height: 8),
 
Card(
  elevation: 5,
  child: InkWell( // Añadir InkWell para el efecto táctil
    onTap: () async {
     
      final lat = currentField.latitude;
      final lng = currentField.longitude;
      
      if (lat != null && lng != null) {
        final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
        
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), 
              mode: LaunchMode.externalApplication
            );
          } else {
            debugPrint('No se pudo abrir el mapa');
          }
        } catch (e) {
          debugPrint('Error al abrir el mapa: $e');
        }
      }
    },
    child: const Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.near_me, color: Colors.blue),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Horario',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    const Text(
                                      'La información de horarios la proporciona el propio establecimiento, si tienes alguna duda ponte en contacto con el establecimiento.',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                    SizedBox(height: 18),
                                    Table(
                                      border:
                                          TableBorder.all(color: Colors.grey),
                                      children: currentField
                                          .available_hours.entries
                                          .map((entry) {
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                _getDayInSpanish(entry.key),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                _formatSchedule(entry.value),
                                                style: TextStyle(
                                                    height: 1.5,
                                                    color: Colors.green,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Segunda pestaña: Torneos activos
                    SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Lista de torneos activos...',
                          style: TextStyle(fontSize: 16),
                        ),
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

   String _getDayInSpanish(String englishDay) {
    final Map<String, String> dayTranslations = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };
    return dayTranslations[englishDay.toLowerCase()] ?? englishDay;
  }

  String _formatSchedule(List<String> hours) {
    if (hours.isEmpty) return 'Cerrado';

    List<String> timeSlots = [];
    for (int i = 0; i < hours.length; i += 2) {
      if (i + 1 < hours.length) {
        String startTime = hours[i];
        String endTime = hours[i + 1];

        if (!startTime.contains(':')) startTime += ':00';
        if (!endTime.contains(':')) endTime += ':00';

        timeSlots.add('$startTime a $endTime');
      }
    }

    return timeSlots.join('\n');
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
