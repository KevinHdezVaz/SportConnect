import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/TeamPlayer.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchInfoTab.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/PositionConfig.dart';
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

  int _currentImage = 0;
  late Future<Field> _fieldFuture;
  final StorageService storage = StorageService();
  // Inicializar con una lista vacía
  List<Map<String, dynamic>> positions = [];
  final ValueNotifier<List<Map<String, dynamic>>> _positionsNotifier = 
      ValueNotifier<List<Map<String, dynamic>>>([]);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeams();
    _setupPaymentListener();
    _fieldFuture = getFieldById(widget.match.fieldId!);
    _initializePositions();
  }


 Future<void> _initializePositions() async {
    try {
      final field = await _fieldFuture;
      final newPositions = PositionsConfig.getPositionsForFieldType(field.type);
      setState(() {
        positions = newPositions;
        _positionsNotifier.value = newPositions;
      });
    } catch (e) {
      debugPrint('Error loading positions: $e');
      final defaultPositions = PositionsConfig.getPositionsForFieldType('fut7');
      setState(() {
        positions = defaultPositions;
        _positionsNotifier.value = defaultPositions;
      });
    }
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
      if (!mounted) return;

      switch (status) {
        case PaymentStatus.success:
          setState(() {
            _joinStatus = JoinTeamStatus.success;
            _loadTeams(); // Recargar los equipos
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Te has unido al equipo exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          break;

        case PaymentStatus.failure:
          setState(() => _joinStatus = JoinTeamStatus.error);
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
  _positionsNotifier.dispose();
    _paymentSubscription.cancel();    super.dispose();
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
          MatchInfoTab(
            fieldFuture: _fieldFuture,
            match: widget.match,
          ),
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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final team = snapshot.data![index];
                return _buildTeamSection(
                  team,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _isPositionAvailable(MatchTeam team, String position) {
    // Verificar si la posición ya está ocupada
    return Future.value(
        !team.players.any((player) => player.position == position));
  } 

  Widget _buildTeamSection(MatchTeam team, {bool canJoin = true}) {
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
  final positions = PositionsConfig.getPositionsForFieldType(widget.match.gameType);

  // Crear mapa de jugadores por posición
  final Map<String, TeamPlayer> playersByPosition = {};
  for (var player in team.players) {
    if (player.position != null) {
      playersByPosition[player.position] = player;
    }
  }

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
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${team.playerCount}/${team.maxPlayers}',
              style: TextStyle(
                color: Colors.black.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        Container(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildJoinButton(team, teamColor),
              ...positions.map((positionData) {
                final position = positionData['name'];
                final player = playersByPosition[position];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _buildPlayerSlot(
                    position,
                    player,
                    teamColor,
                    icon: positionData['icon'],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget _buildPlayerSlot(String position, TeamPlayer? player, Color teamColor, {String? icon}) {
  final bool isAvailable = player == null;
  String? imageUrl;
  if (player?.user?.profileImage != null) {
    imageUrl = 'https://proyect.aftconta.mx/storage/${player!.user!.profileImage}';
  }

  return Container(
    width: 85,
    margin: EdgeInsets.all(8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAvailable ? Colors.grey.shade300 : teamColor,
                  width: 2,
                ),
                color: isAvailable ? Colors.grey.shade100 : Colors.white,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: isAvailable ? Colors.grey.shade200 : Colors.grey[200],
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: isAvailable
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null)
                            Image.asset(
                              icon,
                              width: 24,
                              height: 24,
                              color: Colors.grey.shade400,
                            ),
                        ],
                      )
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          player?.user?.name ?? 'Disponible',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isAvailable ? Colors.grey.shade400 : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          position,
          style: TextStyle(
            fontSize: 11,
            color: isAvailable ? Colors.black : Colors.black,
          ),
        ),
      ],
    ),
  );
}

  Future<bool> _checkUserInTeam(List<MatchTeam> teams) async {
    final currentUserId = await AuthService().getCurrentUserId();
    if (currentUserId == null) return false;

    // Revisar si el usuario está en cualquier equipo
    for (var team in teams) {
      for (var player in team.players) {
        if (player.user?.id == currentUserId) {
          debugPrint(
              'Usuario ${currentUserId} encontrado en equipo ${team.name}');
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildJoinButton(MatchTeam team, Color teamColor) {
    return FutureBuilder<List<MatchTeam>>(
      future: _teamsFuture,
      builder: (context, teamsSnapshot) {
        if (!teamsSnapshot.hasData) {
          return SizedBox();
        }

        return FutureBuilder<bool>(
          future: _checkUserInTeam(teamsSnapshot.data!),
          builder: (context, isInAnyTeamSnapshot) {
            if (!isInAnyTeamSnapshot.hasData) {
              return SizedBox();
            }

            // Si el usuario está en algún equipo
            if (isInAnyTeamSnapshot.data == true) {
              // Verificar si está en este equipo específico
              return FutureBuilder<bool>(
                future: _isUserInTeam(team),
                builder: (context, isInThisTeamSnapshot) {
                  // Solo mostrar el botón "Salir" si está en este equipo
                  if (isInThisTeamSnapshot.data == true) {
                    return Container(
                      width: 80,
                      margin: EdgeInsets.all(8),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => _showLeaveTeamDialog(team),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Icon(Icons.exit_to_app, color: Colors.red),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Salir',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }
                  // Si está en otro equipo, no mostrar ningún botón
                  return SizedBox();
                },
              );
            }

            // Si no está en ningún equipo y el equipo no está lleno, mostrar "Unirme"
            if (team.playerCount < team.maxPlayers) {
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

            return SizedBox();
          },
        );
      },
    );
  }

  void _showLeaveTeamDialog(MatchTeam team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Abandonar equipo',
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          '¿Estás seguro que deseas abandonar el equipo?',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveTeam();
            },
            child: Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _isUserInTeam(MatchTeam team) async {
    final currentUserId = await AuthService().getCurrentUserId();
    if (currentUserId == null) return false;

    // Depurar información
    debugPrint('Current User ID: $currentUserId');
    team.players.forEach((player) {
      debugPrint('Player ID: ${player.user?.id}, Name: ${player.user?.name}');
    });

    return team.players.any(
        (player) => player.user?.id.toString() == currentUserId.toString());
  }

// Método para salir del equipo
  Future<void> _leaveTeam() async {
    try {
      await MatchService().leaveTeam(widget.match.id);

      // Recargar los equipos
      setState(() {
        _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Has abandonado el equipo exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abandonar el equipo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _joinTeam(int teamId, String position) async {
    setState(() {
      _isLoading = true;
      _joinStatus = JoinTeamStatus.processing;
    });

    try {
      await MatchService().processTeamJoinPayment(
          teamId, position, widget.match.price, widget.match.id);

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
  debugPrint('Game Type from match: ${widget.match.gameType}');
  final availablePositions = PositionsConfig.getPositionsForFieldType(widget.match.gameType);

  showDialog(
    context: context,
    barrierDismissible: false, // Evitar que el usuario cierre el diálogo durante el proceso
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return WillPopScope(
          onWillPop: () async => !_isLoading, // Prevenir cerrar con el botón atrás durante la carga
          child: Stack(
            children: [
              AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seleccionar posición',
                      style: TextStyle(color: Colors.black),
                    ),
                    _showStatusIndicator()
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availablePositions.map((position) {
                      bool isOccupied = team.players.any(
                          (player) => player.position == position['name']);

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          enabled: !isOccupied && !_isLoading,
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isOccupied ? Colors.grey.shade200 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              position['icon'],
                              width: 24,
                              height: 24,
                              color: isOccupied || _isLoading ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          title: Text(
                            position['name'],
                            style: TextStyle(
                              color: isOccupied || _isLoading ? Colors.grey.shade400 : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: isOccupied
                              ? Text(
                                  'Posición ocupada',
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 12,
                                  ),
                                )
                              : Text(
                                  'Disponible',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                          onTap: (isOccupied || _isLoading)
                              ? null
                              : () async {
                                  setDialogState(() => _isLoading = true);
                                  await _handleJoinTeam(team, position['name']);
                                  if (!mounted) return;
                                  setDialogState(() => _isLoading = false);
                                },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Uniéndose al equipo...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _handleJoinTeam(MatchTeam team, String position) async {
  try {
    if (widget.match.price > 0) {
      await MatchService().processTeamJoinPayment(
        team.id,
        position,
        widget.match.price,
        widget.match.id,
      );
    } else {
      await MatchService().joinTeam(
        team.id,
        position,
        widget.match.id,
      );
    }

    setState(() {
      _joinStatus = JoinTeamStatus.success;
    });

    Navigator.of(context).pop();

    setState(() {
      _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Te has unido al equipo exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('Error al unirse al equipo: $e');
    setState(() => _joinStatus = JoinTeamStatus.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
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
