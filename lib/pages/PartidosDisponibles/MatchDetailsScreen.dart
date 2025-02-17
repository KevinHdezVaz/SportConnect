import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MathPartido match; // Cambia Match por MathPartido
  const MatchDetailsScreen({Key? key, required this.match}) : super(key: key);
  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

enum JoinTeamStatus { initial, processing, success, error }

JoinTeamStatus _joinStatus = JoinTeamStatus.initial;

class _MatchDetailsScreenState extends State<MatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<MatchTeam>> _teamsFuture;
  late StreamSubscription<PaymentStatus> _paymentSubscription;
  bool _isLoading = false;
  final List<Map<String, dynamic>> positions = [
    {'name': 'Portero', 'icon': 'assets/logos/portero.png'},
    {'name': 'Defensa Central', 'icon': 'assets/logos/patada.png'},
    {'name': 'Lateral Derecho', 'icon': 'assets/logos/voleo.png'},
    {'name': 'Lateral Izquierdo', 'icon': 'assets/logos/voleo.png'},
    {'name': 'Mediocampista Defensivo', 'icon': 'assets/logos/disparar.png'},
    {'name': 'Mediocampista Ofensivo', 'icon': 'assets/logos/disparar.png'},
    {'name': 'Delantero', 'icon': 'assets/logos/patear.png'},
  ];
  int _currentImage = 0;
  late Future<Field> _fieldFuture;
  final StorageService storage = StorageService();

  int? _selectedTeamId;
  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeams();
    _setupPaymentListener();
    _fieldFuture = getFieldById(widget.match.fieldId!);
  }

  void _loadTeams() {
    _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
  }

  Future<Field> getFieldById(int fieldId) async {
    final url = Uri.parse('$baseUrl/fields/$fieldId');
    print('URL de la solicitud: $url');

    final token = await storage.getToken();
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token', // Incluye el token en la solicitud
      },
    );

    print('Código de estado: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode == 200) {
      return Field.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load field');
    }
  }

  void _setupPaymentListener() {
    _paymentSubscription =
        paymentStatusController.stream.listen((status) async {
      switch (status) {
        case PaymentStatus.success:
          try {
            if (_selectedTeamId != null && _selectedPosition != null) {
              await MatchService()
                  .joinTeam(_selectedTeamId!, _selectedPosition!);
              setState(() {
                _loadTeams();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Te has unido al equipo exitosamente')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al unirse al equipo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        case PaymentStatus.failure:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El pago no se completó'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _paymentSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Detalles del Partido',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          indicatorColor:
              Colors.blue, // Color del indicador de la pestaña seleccionada
          labelColor:
              Colors.white, // Color del texto de la pestaña seleccionada
          unselectedLabelColor: const Color.fromARGB(255, 182, 190,
              204), // Color del texto de las pestañas no seleccionadas
          controller: _tabController,
          tabs: [
            Tab(text: 'INFORMACIÓN'),
            Tab(text: 'PARTICIPANTES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildTeamsTab(),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return FutureBuilder<List<MatchTeam>>(
      future: _teamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error cargando equipos'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay equipos disponibles'));
        }

        return FutureBuilder<bool>(
          future: _checkUserInTeam(snapshot.data!),
          builder: (context, userInTeamSnapshot) {
            final bool canJoin = !(userInTeamSnapshot.data ?? false);

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final team = snapshot.data![index];
                return _buildTeamSection(
                  team,
                  canJoin: canJoin,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTeamSection(MatchTeam team, {bool canJoin = true}) {
    // Mapa de nombres de colores a MaterialColor o Color
    final Map<String, Color> colorMap = {
      'Rojo': Colors.red,
      'Azul': Colors.blue,
      'Verde': Colors.green,
      'Amarillo': Colors.yellow,
      'Blanco': const Color(0xFFFFFFFF),
      'Negro': const Color(0xFF000000),
      'Naranja': Colors.orange,
    };
    final Color teamColor = colorMap[team.color] ?? Colors.grey;

// Agregar prints para debug
    print('Team ${team.name} players: ${team.players.length}');
    team.players.forEach((player) {
      print('Player: ${player.user?.name}, Position: ${player.position}');
    });

    final List<String> defaultPositions = [
      'Portero',
      'L.Derecho',
      'L.Izquierdo',
      'Central',
      'Central ofensivo',
      'Delantero'
    ];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: teamColor.withOpacity(0.2),
              child: Text(team.emoji ?? '⚽'),
            ),
            title: Text(
              team.name,
              style: TextStyle(
                color: teamColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              '${team.playerCount}/${team.maxPlayers} jugadores',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (canJoin) _buildJoinButton(team, teamColor),
                ...defaultPositions.map((position) {
                  // Buscar si hay un jugador en esta posición
                  TeamPlayer? player = team.players.firstWhere(
                    (p) => p.position == position,
                    orElse: () => TeamPlayer(
                      position: position,
                      equipoPartidoId: team.id,
                    ),
                  );
                  print(
                      'Position: $position, Found player: ${player.user?.name}');
                  return _buildPlayerSlot(position, player, teamColor);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(
      String position, TeamPlayer? player, Color teamColor) {
    String? imageUrl;
    if (player?.user?.profileImage != null) {
      imageUrl =
          'https://proyect.aftconta.mx/storage/${player!.user!.profileImage}';
    }

    return Container(
      width: 85,
      margin: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: player?.user == null ? Colors.grey : teamColor,
                width: 2,
                style: player?.user == null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: player?.user == null
                  ? Icon(Icons.person_outline, color: Colors.grey)
                  : null,
            ),
          ),
          SizedBox(height: 8),
          Text(
            player?.user?.name ?? 'Disponible',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: player?.user != null ? teamColor : Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            position,
            style: TextStyle(fontSize: 11, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkUserInTeam(List<MatchTeam> teams) async {
    final currentUserId = await AuthService().getCurrentUserId();
    if (currentUserId == null) return false;

    return teams.any((team) =>
        team.players.any((player) => player.user?.id == currentUserId));
  }

  Widget _buildJoinButton(MatchTeam team, Color teamColor) {
    // Si el equipo está lleno, no mostrar el botón
    if (team.playerCount >= team.maxPlayers) return SizedBox();

    final currentUserId = AuthService().getCurrentUserId();

    // Verificar si el usuario ya está en algún equipo
    bool userIsInAnyTeam =
        team.players.any((player) => player.user?.id == currentUserId);

    // Si el usuario ya está en un equipo, no mostrar el botón de unirse
    if (userIsInAnyTeam) return SizedBox();

    return Container(
      width: 80,
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showJoinTeamDialog(team),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: teamColor,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(Icons.add, color: teamColor),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Unirme',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(TeamPlayer player) {
    String? imageUrl;
    if (player.user?.profileImage != null) {
      imageUrl =
          'https://proyect.aftconta.mx/storage/${player.user!.profileImage}';
    }

    return Container(
      width: 85,
      margin: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: player.user == null
                  ? Border.all(
                      color: Colors.grey,
                      width: 2,
                      style: BorderStyle.solid,
                    )
                  : null,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: player.user == null
                  ? Icon(Icons.person_outline, color: Colors.grey)
                  : null,
            ),
          ),
          SizedBox(height: 8),
          Text(
            player.user?.name ?? 'Disponible',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: player.user != null ? Colors.blue : Colors.green,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            player.position,
            style: TextStyle(fontSize: 11, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // En el método _joinTeam:
  Future<void> _joinTeam(int teamId, String position) async {
    setState(() {
      _isLoading = true;
      _joinStatus = JoinTeamStatus.processing;
    });

    try {
      // Pasar el match_id desde widget.match.id
      await MatchService().processTeamJoinPayment(teamId, position,
          widget.match.price, widget.match.id // Añadir el match_id
          );

      // No hacer nada más aquí - el listener se encargará del resto
    } catch (e) {
      setState(() => _joinStatus = JoinTeamStatus.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showJoinTeamDialog(MatchTeam team) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seleccionar posición',
                style: TextStyle(color: Colors.black),
              ),
              _showStatusIndicator() // Aquí se agrega el indicador
            ],
          ),
          content: _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Procesando pago...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: positions
                        .map((position) => ListTile(
                              leading: Image.asset(
                                position['icon'],
                                width: 30,
                                height: 30,
                              ),
                              title: Text(
                                position['name'],
                                style: TextStyle(color: Colors.black),
                              ),
                              onTap: () {
                                _selectedTeamId = team.id;
                                _selectedPosition = position['name'];
                                _joinTeam(team.id, position['name']);
                              },
                            ))
                        .toList(),
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Field>(
            future: _fieldFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error cargando la cancha'));
              }

              if (!snapshot.hasData) {
                return Center(child: Text('No se encontró la cancha'));
              }

              final field = snapshot.data!;

              return Column(
                children: [
                  // Carrusel de imágenes mejorado
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 250, // Aumentar la altura
                              viewportFraction: 0.9,
                              onPageChanged: (index, _) =>
                                  setState(() => _currentImage = index),
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 3),
                            ),
                            items: (field.images ?? []).map((url) {
                              final fullImageUrl = Uri.parse(baseUrl)
                                  .replace(path: url)
                                  .toString();

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
                                            imageUrl: fullImageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                _buildShimmer(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
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
                                  imageUrl: fullImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      _buildShimmer(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              (field.images ?? []).asMap().entries.map((entry) {
                            return Container(
                              width: 10,
                              height: 10,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImage == entry.key
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de información básica de la cancha
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.name,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            text:
                                '${field.municipio ?? "Ubicación no disponible"}',
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.sports_soccer,
                            text: 'Tipo: ${field.type}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de amenidades (ocupa todo el ancho)
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity, // Ocupa todo el ancho
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amenidades:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8, // Espaciado vertical entre elementos
                            children: (field.amenities ?? []).map((amenity) {
                              return Chip(
                                label: Text(amenity),
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                labelStyle: TextStyle(color: Colors.blue),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de reglas importantes
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity, // Ocupa todo el ancho
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reglas importantes:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildRuleItem(
                              '⏰ Llega 15 minutos antes de tu horario.'),
                          _buildRuleItem(
                              '👕 Usa vestimenta adecuada (tenis y ropa deportiva).'),
                          _buildRuleItem(
                              '🚫 Respeta el tiempo de juego y no lo excedas.'),
                          _buildRuleItem(
                              '🧹 Mantén la cancha limpia y recoge tu basura.'),
                          _buildRuleItem(
                              '🤝 Sé respetuoso con los demás jugadores.'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Botón para ver la ubicación en Google Maps
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openMaps(field.latitude!, field.longitude!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(Icons.map, color: Colors.white),
                      label: Text(
                        'Ver ubicación en Maps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

// Método auxiliar para construir filas de información
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    TextStyle? textStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        SizedBox(width: 10),
        Text(
          text,
          style: textStyle ??
              TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
        ),
      ],
    );
  }

// Método para construir un ítem de regla
  Widget _buildRuleItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Método para abrir Google Maps
  void _openMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir Google Maps';
    }
  }

// Método para construir el efecto de shimmer (placeholder)
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _showStatusIndicator() {
    switch (_joinStatus) {
      case JoinTeamStatus.processing:
        return CircularProgressIndicator();
      case JoinTeamStatus.success:
        return Icon(Icons.check_circle, color: Colors.green);
      case JoinTeamStatus.error:
        return Icon(Icons.error, color: Colors.red);
      default:
        return SizedBox();
    }
  }
}
