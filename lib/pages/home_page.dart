import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/Story.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/AvailableMatchesScreen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/invitaciones.screen.dart';
import 'package:user_auth_crudd10/pages/screens/MatchRating/MatchRatingScreen.dart';
import 'package:user_auth_crudd10/pages/screens/PlayerProfilePage.dart';
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
  late Future<List<MathPartido>> matchesToRateFuture;
late Future<List<dynamic>> topMvpPlayersFuture;  

  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];

@override
  void initState() {
    super.initState();
    _cargarDatos();
    futureStories = StoriesService().getStories();
    _loadUserProfile();
    _loadInvitaciones();
    matchesToRateFuture = _matchService.getMatchesToRate();
    topMvpPlayersFuture = _matchService.getTopMvpPlayers();  
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

  Future<void> _handleRefresh() async {
    setState(() {
      futureTorneos = TorneoService().getTorneos();
      matchesToRateFuture = _matchService.getMatchesToRate();
      futureStories = StoriesService().getStories();
      futureMatches = _matchService.getAvailableMatches(selectedDate);
      topMvpPlayersFuture = _matchService.getTopMvpPlayers(); // Recargar top MVP
    });
await Future.wait([futureTorneos, futureStories, futureMatches, matchesToRateFuture, topMvpPlayersFuture]);
    await _loadUserProfile();
    await _loadInvitaciones();
  }

  void _reloadMatchesToRate() {
    setState(() {
      matchesToRateFuture = _matchService.getMatchesToRate();
    });
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
                onRefresh: _handleRefresh,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.blue),
                                            )
                                          : Icon(Icons.person, color: Colors.blue),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Hola,', style: TextStyle(color: Color.fromARGB(255, 87, 84, 84), fontSize: 13)),
                                        Text(
                                          userData!['name'] ?? '',
                                          style: GoogleFonts.inter(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)),
                                    child: Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.notifications_none, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => InvitacionesScreen()))
                                                .then((_) => _loadInvitaciones());
                                          },
                                        ),
                                        if (_invitacionesPendientes > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                              child: Text(
                                                _invitacionesPendientes.toString(),
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                                if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(children: [const SizedBox(height: 15), const StoriesSection()]);
                              },
                            ),FutureBuilder<List<dynamic>>(
                              future: topMvpPlayersFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                                }
                                if (snapshot.hasError) {
                                  return const SizedBox(height: 100, child: Center(child: Text('Error al cargar MVPs')));
                                }
                                final topPlayers = snapshot.data ?? [];
                                if (topPlayers.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                                      child: Text(
                                        'Top Jugadores MVP ⚽',
                                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: topPlayers.length,
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        itemBuilder: (context, index) {
                                          final player = topPlayers[index];
                                          final imageUrl = player['profile_image'] != null
                                              ? 'https://proyect.aftconta.mx/storage/${player['profile_image']}'
                                              : null;
                                          return GestureDetector(
                                            onTap: () =>   Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerProfilePage(userId: player['user_id']),
                ),
              ),
                                            child: Container(
                                              width: 80,
                                              margin: EdgeInsets.only(right: 16),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 30,
                                                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                                                    child: imageUrl == null ? Icon(Icons.person, color: Colors.grey) : null,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    player['name'],
                                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                                                    textAlign: TextAlign.center,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),

/*
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Torneos Activos', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentsScreen())),
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
                                          Text('Error de conexión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () => setState(() => futureTorneos = TorneoService().getTorneos()),
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
                                      return Container(width: 320, margin: EdgeInsets.only(right: 8), child: _buildTorneoCard(context, torneo));
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
                            */

                            Divider(color: Colors.grey[400], thickness: 1), // Línea divisoria

                            SizedBox(height: 24),
                            FutureBuilder<List<MathPartido>>(
                              future: matchesToRateFuture,
                              builder: (context, snapshot) {
                                debugPrint('FutureBuilder state: ${snapshot.connectionState}');
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
                                }
                                if (snapshot.hasError) {
                                  debugPrint('Error en FutureBuilder: ${snapshot.error}');
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 40),
                                        SizedBox(height: 8),
                                        Text('Error al cargar partidos: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                                      ],
                                    ),
                                  );
                                }

                                final matches = snapshot.data ?? [];
                                debugPrint('Partidos encontrados: ${matches.length}');

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Text(
                                        'Califica tus partidos terminados',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ),
                                    if (matches.isEmpty)
                                      Container(
                                        padding: EdgeInsets.all(20),
                                        width: double.infinity,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sports_soccer_outlined, size: 50, color: Colors.grey[400]),
                                            SizedBox(height: 16),
                                            Text(
                                              '¡No tienes partidos pendientes por calificar!',
                                              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Cuando termines un partido, podrás calificarlo aquí.',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 180,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: matches.length,
                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                          itemBuilder: (context, index) {
                                            final match = matches[index];
                                            return Container(
                                              width: 280,
                                              margin: EdgeInsets.only(right: 16),
                                              child: Card(
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                child: Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundColor: Colors.blue.withOpacity(0.1),
                                                            child: Icon(Icons.sports_soccer, color: Colors.blue),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              match.name,
                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Horario: ${match.formattedStartTime} - ${match.formattedEndTime}',
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                                      ),
                                                      if (match.field != null)
                                                        Text(
                                                          'Cancha: ${match.field!.name}',
                                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                                        ),
                                                      Spacer(),
                                                      Align(
                                                        alignment: Alignment.bottomRight,
                                                        child: ElevatedButton(
                                                          onPressed: () async {
                                                            final result = await Navigator.of(context).push(
                                                              MaterialPageRoute(
                                                                builder: (context) => MatchRatingScreen(matchId: match.id),
                                                              ),
                                                            );
                                                            if (result == true) {
                                                              _reloadMatchesToRate(); // Recargar partidos por calificar
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.blue,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                                          ),
                                                          child: Text(
                                                            'Calificar',
                                                            style: TextStyle(color: Colors.white, fontSize: 14),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            Divider(color: Colors.grey[400], thickness: 1), // Línea divisoria
                            SizedBox(height: 24),
                            
                            const Text('Partidos Disponibles', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetails(torneo: torneo))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    torneo.imagenesTorneo!.isNotEmpty ? torneo.imagenesTorneo![0] : 'https://via.placeholder.com/150',
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
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                    child: Text('Inscripciones Abiertas', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(torneo.nombre, style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${torneo.minimoEquipos} equipos inscritos', style: TextStyle(color: Colors.black, fontSize: 12)),
                      Spacer(),
                      Text('\$${torneo.cuotaInscripcion}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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