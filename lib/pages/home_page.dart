import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/Story.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/invitaciones.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentDetails.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentScreen.dart';
import 'package:user_auth_crudd10/pages/screens/stories/StoriesSection.dart';
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
    @override
  void initState() {
    super.initState();
    _cargarDatos();
    futureStories = StoriesService().getStories();
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

  @override
  Widget build(BuildContext context) {
    if (userData != null && userData!['profile_image'] != null) {
      imageUrl =
          'https://proyect.aftconta.mx/storage/${userData!['profile_image']}';
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // Contenido principal
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Buscador
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
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
                                  // Foto de perfil
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
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Icon(Icons.person,
                                                      color: Colors.blue),
                                            )
                                          : Icon(Icons.person,
                                              color: Colors.blue),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Saludo y nombre
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Hola,',
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                                255, 87, 84, 84),
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
                                  // Botones
                                  //aqui va las notificaciones de invitaciones
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withOpacity(0.1),
                                    ),
                                    child: Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.notifications_none,
                                              color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      InvitacionesScreen()),
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
                                                _invitacionesPendientes
                                                    .toString(),
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
                                  )
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Add after search container
                            const StoriesSection(),
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
                                      MaterialPageRoute(
                                          builder: (_) => TournamentsScreen()),
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Error de conexión',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                futureTorneos = TorneoService()
                                                    .getTorneos();
                                              });
                                            },
                                            child: Text('Reintentar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                        child: Text(
                                            'No hay torneos disponibles.'));
                                  }

                                  return CarouselSlider.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index, realIndex) {
                                      Torneo torneo = snapshot.data![index];
                                      return Container(
                                        width:
                                            320, // Ancho fijo para cada tarjeta
                                        margin: EdgeInsets.only(
                                            right: 8), // Espacio entre tarjetas
                                        child:
                                            _buildTorneoCard(context, torneo),
                                      );
                                    },
                                    options: CarouselOptions(
                                      height: 220,
                                      aspectRatio: 16 / 9,
                                      viewportFraction:
                                          0.8, // Muestra parcialmente las tarjetas adyacentes
                                      initialPage: 0,
                                      enableInfiniteScroll: true,
                                      reverse: false,
                                      autoPlay: true,
                                      autoPlayInterval: Duration(seconds: 5),
                                      autoPlayAnimationDuration:
                                          Duration(milliseconds: 800),
                                      autoPlayCurve: Curves.fastOutSlowIn,
                                      enlargeCenterPage: true,
                                      scrollDirection: Axis.horizontal,
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 24),

                            // Sección de partidos disponibles
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Partidos Disponibles',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text('Ver todos'),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return AvailableMatchCard();
                              },
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

Widget _buildTorneoCard(BuildContext context, Torneo torneo) {
  return Card(
    margin: EdgeInsets.all(8),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TournamentDetails(
                    torneo: torneo,
                  )),
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
                  height: 100, // Altura más pequeña para la imagen
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
            padding: EdgeInsets.all(12), // Padding más pequeño
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  torneo.nombre,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16, // Tamaño de fuente más pequeño
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people,
                        size: 12, color: Colors.grey), // Ícono más pequeño
                    SizedBox(width: 4),
                    Text(
                      '${torneo.minimoEquipos} equipos inscritos',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12, // Tamaño de fuente más pequeño
                      ),
                    ),
                    Spacer(),
                    Text(
                      '\$${torneo.cuotaInscripcion}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12, // Tamaño de fuente más pequeño
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

// Widget para tarjeta de partido disponible
class AvailableMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '15',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'ENE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partido Amistoso',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '8 jugadores necesarios',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Unirse',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
