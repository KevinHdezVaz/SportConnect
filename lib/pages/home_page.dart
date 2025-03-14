import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/Notificacion.dart';
import 'package:user_auth_crudd10/model/Story.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/AvailableMatchesScreen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/NotificationHistoryScreen.dart';
import 'package:user_auth_crudd10/pages/screens/MatchRating/MatchRatingScreen.dart';
import 'package:user_auth_crudd10/pages/screens/PlayerProfilePage.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentDetails.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentScreen.dart';
import 'package:user_auth_crudd10/pages/screens/stories/StoriesSection.dart';
import 'package:user_auth_crudd10/services/BannerService.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/services/NotificationServiceExtension.dart';
import 'package:user_auth_crudd10/services/StoriesService.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/services/torneo_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

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
  late Future<List<String>> futureBanners; // Agrega Future para banners
  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];
  bool _hasUnreadNotifications = false;
  final _notificationService = NotificationServiceExtension();
  bool _isLoading = true;
  List<Notificacion> _notifications = [];
  bool _showTournaments = true; // New flag for tournaments
  final StorageService _storageService = StorageService();

  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    futureStories = StoriesService().getStories();
    _loadUserProfile();
    _loadInvitaciones();
    futureBanners = BannerService().getBanners(); // Inicializa los banners
    matchesToRateFuture = _matchService.getMatchesToRate();
    topMvpPlayersFuture = _matchService.getTopMvpPlayers();
    for (int i = 0; i < 7; i++) {
      next7Days.add(DateTime.now().add(Duration(days: i)));
    }
    _checkUnreadNotifications();
    _markAllNotificationsAsRead();
    _loadMatches();
    _loadNotifications();
    fetchSettings();
  }

  final _authService = AuthService();
  Map<String, dynamic>? userData;
  String? imageUrl;

  Future<void> fetchSettings() async {
    final token = await _storageService.getToken();

    try {
      final url = Uri.parse('$baseUrl/settings/show_tournaments');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _showTournaments = data['show_tournaments'] == 'true';
          _isLoadingSettings = false;
        });
      } else {
        throw Exception(
            'Error al cargar configuraciones: Código de estado ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingSettings = false;
        _showTournaments = true; // Valor por defecto si falla la solicitud
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar configuraciones: $e')),
      );
    }
  }

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

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true); // Muestra el indicador de carga
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false; // Oculta el indicador de carga
      });
    } catch (e) {
      setState(() => _isLoading =
          false); // Asegura que el loading se detenga incluso en error
    }
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

  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _loadMatches() {
    setState(() {
      futureMatches = _matchService.getAvailableMatches(selectedDate);
    });
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();
      _hasUnreadNotifications =
          notifications.any((notification) => !notification.read);
      setState(() {});
    } catch (e) {
      print('Error al verificar notificaciones no leídas: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      // Después de marcar como leídas, recarga las notificaciones para reflejar el cambio localmente
      await _loadNotifications();
    } catch (e) {
      print('Error al marcar notificaciones como leídas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar notificaciones como leídas')),
      );
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      futureTorneos = TorneoService().getTorneos();
      matchesToRateFuture = _matchService.getMatchesToRate();
      futureStories = StoriesService().getStories();
      futureBanners = BannerService().getBanners(); // Recarga los banners
      futureMatches = _matchService.getAvailableMatches(selectedDate);
      topMvpPlayersFuture =
          _matchService.getTopMvpPlayers(); // Recargar top MVP
    });
    await Future.wait([
      futureTorneos,
      futureStories,
      futureBanners, // Añade banners al refresh
      futureMatches,
      matchesToRateFuture,
      topMvpPlayersFuture
    ]);
    await _loadUserProfile();
    await _loadInvitaciones();
  }

  void _reloadMatchesToRate() {
    setState(() {
      matchesToRateFuture = _matchService.getMatchesToRate();
    });
  }

  void _reloadTopMvpPlayers() {
    setState(() {
      topMvpPlayersFuture =
          _matchService.getTopMvpPlayers(); // Método para recargar top MVP
    });
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Contenedor de la imagen de perfil
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
                                  // Columna con el saludo y el nombre del usuario
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Hola,',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 87, 84, 84),
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
                                  // Ícono de notificaciones con punto rojo
                                  Stack(
                                    children: [
                                      // En _HomePageState de HomePage
                                      IconButton(
                                        icon: Icon(Icons.notifications,
                                            color: Colors.blue),
                                        onPressed: () async {
                                          try {
                                            await _notificationService
                                                .markAllNotificationsAsRead();
                                            setState(() {
                                              _hasUnreadNotifications =
                                                  false; // Quita el punto rojo inmediatamente
                                              print(
                                                  'Punto rojo desactivado: $_hasUnreadNotifications');
                                            });
                                          } catch (e) {
                                            print(
                                                'Error al marcar notificaciones como leídas: $e');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Error al marcar notificaciones como leídas')),
                                            );
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  NotificationHistoryScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      // Punto rojo para notificaciones no leídas
                                      if (_hasUnreadNotifications)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder<List<Story>>(
                              future: futureStories,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    snapshot.hasError ||
                                    !snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(children: [
                                  const SizedBox(height: 15),
                                  const StoriesSection()
                                ]);
                              },
                            ),

                            if (_showTournaments) // Usar un if dentro de la lista de children
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      "Torneos",
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  FutureBuilder<List<Torneo>>(
                                    future: futureTorneos,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }
                                      final torneos = snapshot.data ?? [];
                                      if (torneos.isEmpty) {
                                        return const Text(
                                            'No hay torneos disponibles');
                                      }
                                      return SizedBox(
                                        height: 200,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: torneos.length,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          itemBuilder: (context, index) {
                                            return _buildTorneoCard(
                                                context, torneos[index]);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                            // Sección de Banners con zoom
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 20),
                              child: Text(
                                "Oferta e información",
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),

                            FutureBuilder<List<String>>(
                              future: futureBanners,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildBannerShimmer();
                                }

                                if (snapshot.hasError) {
                                  print(
                                      'Error cargando banners: ${snapshot.error}');
                                  return SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Text(
                                        'Error al cargar banners: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }

                                final banners = snapshot.data;
                                if (banners == null || banners.isEmpty) {
                                  print('No hay banners disponibles');
                                  return SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Text('No hay banners disponibles'),
                                    ),
                                  );
                                }

                                print('Banners cargados: ${banners.length}');
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: CarouselSlider(
                                    options: CarouselOptions(
                                      height: 180,
                                      autoPlay: true,
                                      autoPlayInterval: Duration(seconds: 3),
                                      enlargeCenterPage: true,
                                      viewportFraction: 0.9,
                                    ),
                                    items: banners.map((bannerUrl) {
                                      print('Cargando banner: $bannerUrl');
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ZoomImageScreen(
                                                      imageUrl: bannerUrl),
                                            ),
                                          );
                                        },
                                        child: CachedNetworkImage(
                                          imageUrl: bannerUrl,
                                          fit: BoxFit.cover,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 180,
                                          placeholder: (context, url) =>
                                              _buildBannerShimmer(),
                                          errorWidget: (context, url, error) =>
                                              Center(
                                            child: Icon(Icons.error,
                                                color: Colors.red),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),

                            FutureBuilder<List<dynamic>>(
                              future: topMvpPlayersFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox(
                                      height: 100,
                                      child: Center(
                                          child: CircularProgressIndicator()));
                                }
                                if (snapshot.hasError) {
                                  return const SizedBox(
                                      height: 100,
                                      child: Center(
                                          child: Text('Error al cargar MVPs')));
                                }
                                final topPlayers = snapshot.data ?? [];
                                if (topPlayers.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 28),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Top Jugadores MVP ⚽',
                                            style: GoogleFonts.inter(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Mes: ${DateFormat('MMMM y', 'es').format(DateTime.now())}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: const Color.fromARGB(
                                                    255, 0, 0, 0),
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: topPlayers.length,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemBuilder: (context, index) {
                                          final player = topPlayers[index];
                                          final imageUrl = player[
                                                      'profile_image'] !=
                                                  null
                                              ? 'https://proyect.aftconta.mx/storage/${player['profile_image']}'
                                              : null;
                                          final position = index + 1;
                                          return GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PlayerProfilePage(
                                                        userId:
                                                            player['user_id']),
                                              ),
                                            ),
                                            child: Container(
                                              width: 90,
                                              margin:
                                                  EdgeInsets.only(right: 16),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 30,
                                                        backgroundImage:
                                                            imageUrl != null
                                                                ? NetworkImage(
                                                                    imageUrl)
                                                                : null,
                                                        child: imageUrl == null
                                                            ? Icon(Icons.person,
                                                                color:
                                                                    Colors.grey)
                                                            : null,
                                                        backgroundColor:
                                                            Colors.blue[100],
                                                      ),
                                                      if (index < 3)
                                                        Positioned(
                                                          top: 5,
                                                          left: 5,
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    6),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  _getPositionColor(
                                                                      index),
                                                            ),
                                                            child: Text(
                                                              position
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    player['name'],
                                                    style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.black),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
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
                            FutureBuilder<List<MathPartido>>(
                              future: matchesToRateFuture,
                              builder: (context, snapshot) {
                                debugPrint(
                                    'FutureBuilder state: ${snapshot.connectionState}');
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  debugPrint(
                                      'Error en FutureBuilder: ${snapshot.error}');
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.error_outline,
                                            color: Colors.red, size: 40),
                                        SizedBox(height: 8),
                                        Text(
                                          'Error al cargar partidos: ${snapshot.error}',
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final matches = snapshot.data ?? [];
                                debugPrint(
                                    'Partidos encontrados: ${matches.length}');

                                return Column(
                                  children: [
                                    Visibility(
                                      visible: matches.isNotEmpty,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Divider(
                                              color: Colors.grey[400],
                                              thickness: 1),
                                          SizedBox(height: 24),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Text(
                                              'Califica tus partidos terminados',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 200,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: matches.length,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              itemBuilder: (context, index) {
                                                final match = matches[index];
                                                return Container(
                                                  width: 280,
                                                  margin: EdgeInsets.only(
                                                      right: 16),
                                                  child: Card(
                                                    elevation: 2,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(12),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.blue
                                                                        .withOpacity(
                                                                            0.1),
                                                                child: Icon(
                                                                    Icons
                                                                        .sports_soccer,
                                                                    color: Colors
                                                                        .blue),
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  match.name,
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 8),
                                                          RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      '📅 Fecha: ', // Emoji de calendario
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black, // "Fecha:" en negro
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: match
                                                                      .formattedDate,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .orange, // Fecha en naranja
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  4), // Espacio entre los textos
                                                          RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      '⏰ Horario: ', // Emoji de reloj
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black, // "Horario:" en negro
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      '${match.formattedStartTime} - ${match.formattedEndTime}',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .green, // Horario en verde
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(height: 4),
                                                          if (match.field !=
                                                              null)
                                                            RichText(
                                                              text: TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    text:
                                                                        '⚽ Cancha: ', // Emoji de pelota de fútbol
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black, // "Cancha:" en negro
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text: match
                                                                        .field!
                                                                        .name,
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black, // Nombre de la cancha en negro
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          Spacer(),
                                                          Align(
                                                            alignment: Alignment
                                                                .bottomRight,
                                                            child:
                                                                ElevatedButton(
                                                              onPressed:
                                                                  () async {
                                                                final result =
                                                                    await Navigator.of(
                                                                            context)
                                                                        .push(
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        MatchRatingScreen(
                                                                            matchId:
                                                                                match.id),
                                                                  ),
                                                                );
                                                                if (result ==
                                                                    true) {
                                                                  _reloadMatchesToRate(); // Recargar partidos por calificar
                                                                  _reloadTopMvpPlayers(); // Recargar top MVP después de calificar
                                                                }
                                                              },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.blue,
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8)),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            16),
                                                              ),
                                                              child: Text(
                                                                'Calificar',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14),
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
                                          SizedBox(height: 24), // Espacio abajo
                                          Divider(
                                              color: Colors.grey[400],
                                              thickness: 1), // Divider abajo
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Partidos disponibles',
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
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

  Color _getPositionColor(int index) {
    switch (index) {
      case 0: // 1er lugar
        return Colors.amber;
      case 1: // 2do lugar
        return Colors.grey;
      case 2: // 3er lugar
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTorneoCard(BuildContext context, Torneo torneo) {
    return Container(
      width: 200, // Ancho fijo para cada tarjeta en el ListView horizontal
      margin: EdgeInsets.all(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TournamentDetails(torneo: torneo))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      height: 100, // Altura fija para la imagen
                      width: double
                          .infinity, // Esto ahora es seguro porque está dentro de un Container con ancho fijo
                      child: Image.network(
                        torneo.imagenesTorneo!.isNotEmpty
                            ? torneo.imagenesTorneo![0]
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'Inscripciones Abiertas',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${torneo.minimoEquipos} equipos inscritos',
                            style: TextStyle(color: Colors.black, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${torneo.cuotaInscripcion}',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
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

class ZoomImageScreen extends StatelessWidget {
  final String imageUrl;

  const ZoomImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Regresar'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: BoxDecoration(color: Colors.black),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text('Error al cargar la imagen',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
