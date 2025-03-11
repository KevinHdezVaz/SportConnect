import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchDetailsScreen.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/BookingDialog%20.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;

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
  List<dynamic> activeMatches = [];
  bool isLoadingMatches = true;
  late Future<List<MathPartido>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    currentField = widget.field;
    _controller =
        AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _loadActiveMatches();
    _matchesFuture = MatchService().getAvailableMatches(DateTime.now());
  }

  Future<void> _loadActiveMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/fields/${currentField.id}/matches'),
        headers: await _authService.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          activeMatches = json.decode(response.body)['matches'];
          isLoadingMatches = false;
        });
      }
    } catch (e) {
      print('Error loading matches: $e');
      setState(() {
        isLoadingMatches = false;
      });
    }
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
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 300.0,
                          viewportFraction: 1.0,
                          onPageChanged: (index, _) =>
                              setState(() => _currentImage = index),
                          autoPlay: true,
                        ),
                        items: (widget.field.images ?? []).map((url) {
                          final fullImageUrl =
                              Uri.parse(baseUrl).replace(path: url).toString();
                          return GestureDetector(
                            onTap: () {
                              // Abrir la imagen en grande con PhotoView
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withOpacity(0.5),
                                builder: (BuildContext context) {
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    insetPadding: EdgeInsets.all(16),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            color: Colors.transparent,
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: PhotoView(
                                              imageProvider:
                                                  CachedNetworkImageProvider(
                                                      fullImageUrl),
                                              minScale: PhotoViewComputedScale
                                                      .contained *
                                                  0.8,
                                              maxScale: PhotoViewComputedScale
                                                      .covered *
                                                  2.0,
                                              backgroundDecoration:
                                                  BoxDecoration(
                                                      color:
                                                          Colors.transparent),
                                              loadingBuilder:
                                                  (context, event) => Center(
                                                child: Container(
                                                  width: 30.0,
                                                  height: 30.0,
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[400],
                                                  size: 50,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.close,
                                                  color: Colors.black),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: fullImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildShimmer(),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Sobre la cancha'),
                      Tab(text: 'Partidos activos'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Primera pestaña: Sobre la cancha
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 81, 139, 190), // Color inicial
                            Color.fromARGB(255, 234, 237, 238), // Color final
                          ],
                          begin:
                              Alignment.center, // Punto de inicio del gradiente
                          end: Alignment
                              .bottomCenter, // Punto final del gradiente
                        ),
                      ),
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
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.black),
                              Expanded(
                                child: Text(
                                  currentField.municipio ??
                                      'Ubicación no disponible',
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
                                    onPressed: () =>
                                        _showBookingDialog(currentField),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Reservar',
                                            style:
                                                TextStyle(color: Colors.white)),
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
                                color: Colors.blue,
                                elevation: 5,
                                child: InkWell(
                                  onTap: () async {
                                    final lat = currentField.latitude;
                                    final lng = currentField.longitude;
                                    if (lat != null && lng != null) {
                                      final url =
                                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                                      try {
                                        if (await canLaunchUrl(
                                            Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication);
                                        } else {
                                          debugPrint(
                                              'No se pudo abrir el mapa');
                                        }
                                      } catch (e) {
                                        debugPrint(
                                            'Error al abrir el mapa: $e');
                                      }
                                    }
                                  },
                                  child: const Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.near_me,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          '¿Cómo llegar?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
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
                  ],
                ),
              ),
// Reemplaza el contenido de la segunda pestaña con:
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: FutureBuilder<List<MathPartido>>(
                    future: _matchesFuture, // Usar la variable almacenada
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar los partidos',
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }

                      final matches = snapshot.data
                              ?.where(
                                  (match) => match.fieldId == widget.field.id)
                              .toList() ??
                          [];

                      if (matches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 56),
                              Icon(Icons.sports_soccer,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay partidos activos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];

                          // Convertir las cadenas a DateTime
                          DateTime startTime =
                              DateFormat('HH:mm:ss').parse(match.startTime);
                          DateTime endTime =
                              DateFormat('HH:mm:ss').parse(match.endTime);

                          // Formatear DateTime a "HH:mm"
                          String formattedStartTime =
                              DateFormat('HH:mm').format(startTime);
                          String formattedEndTime =
                              DateFormat('HH:mm').format(endTime);

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(
                                match.name,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(match.scheduleDate),
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        '$formattedStartTime - $formattedEndTime',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MatchDetailsScreen(match: match),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'Ver',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey[100],
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
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
