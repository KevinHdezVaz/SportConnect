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
  {'name': 'L.Derecho', 'icon': 'assets/logos/voleo.png'},
  {'name': 'L.Izquierdo', 'icon': 'assets/logos/voleo.png'},
  {'name': 'Central', 'icon': 'assets/logos/patada.png'},
  {'name': 'Central ofensivo', 'icon': 'assets/logos/disparar.png'},
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
  _paymentSubscription = paymentStatusController.stream.listen((status) async {
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
    final Map<String, Color> colorMap = {
      'Rojo': Colors.red,
      'Azul': Colors.blue,
      'Verde': Colors.green,
      'Amarillo': Colors.yellow,
      'Blanco': const Color(0xFFFFFFFF),
      'Negro': const Color(0xFF000000),
      'Naranja': Colors.orange,
    };
 
    // Mapear jugadores por posición para acceso rápido
  

   final Color teamColor = colorMap[team.color] ?? Colors.grey;

    // Crear mapa de jugadores por posición
    final Map<String, TeamPlayer> playersByPosition = {};
    for (var player in team.players) {
      debugPrint('Procesando jugador en equipo ${team.name}: posición ${player.position}, usuario: ${player.user?.name}');
      if (player.position != null) {
        playersByPosition[player.position] = player;
      }
    }

    // Imprimir todos los jugadores para debug
    team.players.forEach((player) {
      debugPrint('Jugador en equipo ${team.name}: ${player.user?.name} - ${player.position}');
    });
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
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (canJoin) _buildJoinButton(team, teamColor),
                ...positions.map((positionData) {
                  final position = positionData['name'];
                  final player = playersByPosition[position];
                  debugPrint('Position: $position, Player: ${player?.user?.name}');
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

  // Revisar si el usuario está en cualquier equipo
  for (var team in teams) {
    for (var player in team.players) {
      if (player.user?.id == currentUserId) {
        debugPrint('Usuario ${currentUserId} encontrado en equipo ${team.name}');
        return true;
      }
    }
  }
  return false;
}

Widget _buildJoinButton(MatchTeam team, Color teamColor) {
  return FutureBuilder<bool>(
    future: _checkUserInTeam([team]), // Comprueba solo este equipo
    builder: (context, snapshot) {
      if (snapshot.data == true) {
        // Si el usuario ya está en un equipo, no mostrar el botón
        return SizedBox();
      }

      // Si el equipo está lleno, no mostrar el botón
      if (team.playerCount >= team.maxPlayers) {
        return SizedBox();
      }

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
    },
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

  Future<void> _joinTeam(int teamId, String position) async {
    setState(() {
      _isLoading = true;
      _joinStatus = JoinTeamStatus.processing;
    });

    try { 
      await MatchService().processTeamJoinPayment(teamId, position,
          widget.match.price, widget.match.id 
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
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
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
          content: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: positions.map((position) => ListTile(
                      leading: Image.asset(
                        position['icon'],
                        width: 30,
                        height: 30,
                      ),
                      title: Text(
                        position['name'],
                        style: TextStyle(color: Colors.black),
                      ),
                      onTap: () => _handleJoinTeam(team, position['name']),
                    )).toList(),
                  ),
                ),
        );
      },
    ),
  );
}
Future<void> _handleJoinTeam(MatchTeam team, String position) async {
  setState(() {
    _isLoading = true;
    _joinStatus = JoinTeamStatus.processing;
  });

  try {
    debugPrint('Uniendo al equipo. Team ID: ${team.id}, Position: $position, Match ID: ${widget.match.id}');
    
    // Si hay sistema de pago, usar processTeamJoinPayment
    if (widget.match.price > 0) {
      await MatchService().processTeamJoinPayment(
        team.id,
        position,
        widget.match.price,
        widget.match.id,
      );
    } else {
      // Si no hay pago, usar joinTeam directamente
      await MatchService().joinTeam(
        team.id,
        position,
        widget.match.id,
      );
    }

    setState(() {
      _joinStatus = JoinTeamStatus.success;
    });

    // Cerrar el diálogo
    Navigator.of(context).pop();

    // Recargar los equipos
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
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
