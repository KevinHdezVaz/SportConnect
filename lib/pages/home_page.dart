import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/Story.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/AvailableMatchesScreen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/invitaciones.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentDetails.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentScreen.dart';
import 'package:user_auth_crudd10/pages/screens/stories/StoriesSection.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/services/StoriesService.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
import 'package:user_auth_crudd10/services/torneo_service.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Torneo>> futureTorneos;
  final int count = 0;
  int _invitacionesPendientes = 0;
  final _equipoService = EquipoService();
  late Future<List<Story>> futureStories;
  final MatchService _matchService = MatchService();
  late Future<List<MathPartido>> futureMatches;

  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    futureStories = StoriesService().getStories();
    _loadUserProfile();
    _loadInvitaciones();
    for (int i = 0; i < 7; i++) {
      next7Days.add(DateTime.now().add(Duration(days: i)));
    }
    _loadMatches();
  }

  final _authService = AuthService();
  Map<String, dynamic>? userData;
  String? imageUrl;

  Future<void> _loadInvitaciones() async {
    try {
      final count = await _equipoService.getInvitacionesPendientesCount();
      setState(() {
        _invitacionesPendientes = count;
      });
    } catch (e) {
      print('Error cargando invitaciones: $e');
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      futureTorneos = TorneoService().getTorneos();
      _loadUserProfile();
      _loadInvitaciones();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _authService.getProfile();
      setState(() {
        userData = response;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
    }
  }

  void _loadMatches() {
    setState(() {
      futureMatches = _matchService.getAvailableMatches(selectedDate);
    });
  }

  // Nueva función para manejar la recarga al deslizar hacia abajo
  Future<void> _handleRefresh() async {
    setState(() {
      futureTorneos = TorneoService().getTorneos(); // Recarga torneos
      futureStories = StoriesService().getStories(); // Recarga historias
      futureMatches = _matchService.getAvailableMatches(selectedDate); // Recarga partidos
    });
    await Future.wait([futureTorneos, futureStories, futureMatches]); // Espera a que todos los datos se recarguen
    await _loadUserProfile(); // Recarga el perfil del usuario
    await _loadInvitaciones(); // Recarga las invitaciones
  }

  @override
  Widget build(BuildContext context) {
    if (userData != null && userData!['profile_image'] != null) {
      imageUrl = 'https://proyect.aftconta.mx/storage/${userData!['profile_image']}';
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _handleRefresh, // Función que se ejecuta al deslizar hacia abajo
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Buscador
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(Icons.person, color: Colors.blue),
                                            )
                                          : Icon(Icons.person, color: Colors.blue),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Hola,',
                                          style: TextStyle(
                                            color: Color.fromARGB(255, 87, 84, 84),
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          userData!['name'] ?? '',
                                          style: GoogleFonts.inter(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withOpacity(0.1),
                                    ),
                                    child: Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.notifications_none, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => InvitacionesScreen()),
                                            ).then((_) => _loadInvitaciones());
                                          },
                                        ),
                                        if (_invitacionesPendientes > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                _invitacionesPendientes.toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            FutureBuilder<List<Story>>(
                              future: futureStories,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting ||
                                    snapshot.hasError ||
                                    !snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    const SizedBox(height: 15),
                                    const StoriesSection(),
                                  ],
                                );
                              },
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Torneos Activos',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TournamentsScreen()),
                                    );
                                  },
                                  child: Text('Ver todos'),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: FutureBuilder<List<Torneo>>(
                                future: futureTorneos,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Error de conexión',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                futureTorneos = TorneoService().getTorneos();
                                              });
                                            },
                                            child: Text('Reintentar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Center(child: Text('No hay torneos disponibles.'));
                                  }

                                  return CarouselSlider.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index, realIndex) {
                                      Torneo torneo = snapshot.data![index];
                                      return Container(
                                        width: 320,
                                        margin: EdgeInsets.only(right: 8),
                                        child: _buildTorneoCard(context, torneo),
                                      );
                                    },
                                    options: CarouselOptions(
                                      height: 220,
                                      aspectRatio: 16 / 9,
                                      viewportFraction: 0.8,
                                      initialPage: 0,
                                      enableInfiniteScroll: true,
                                      reverse: false,
                                      autoPlay: true,
                                      autoPlayInterval: Duration(seconds: 5),
                                      autoPlayAnimationDuration: Duration(milliseconds: 800),
                                      autoPlayCurve: Curves.fastOutSlowIn,
                                      enlargeCenterPage: true,
                                      scrollDirection: Axis.horizontal,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 24),

                            const Text(
                              'Partidos Disponibles',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 24),

                            AvailableMatchesScreen(),
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

  Widget _buildTorneoCard(BuildContext context, Torneo torneo) {
    return Card(
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TournamentDetails(torneo: torneo)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    torneo.imagenesTorneo!.isNotEmpty
                        ? torneo.imagenesTorneo![0]
                        : 'https://via.placeholder.com/150',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Inscripciones Abiertas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    torneo.nombre,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${torneo.minimoEquipos} equipos inscritos',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '\$${torneo.cuotaInscripcion}',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}