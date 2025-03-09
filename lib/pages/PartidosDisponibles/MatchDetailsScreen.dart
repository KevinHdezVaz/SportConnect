import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/TeamPlayer.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/Wallet.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/CommentsTab.dart'; // Nueva importación
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchInfoTab.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/PositionConfig.dart';
import 'package:user_auth_crudd10/pages/screens/PlayerProfilePage.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/services/WalletService.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MathPartido match;
  const MatchDetailsScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

enum JoinTeamStatus { initial, processing, success, error }

class _MatchDetailsScreenState extends State<MatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<MatchTeam>> _teamsFuture;
  late StreamSubscription<Map<String, dynamic>> _paymentSubscription;
  bool _isLoading = false;
  JoinTeamStatus _joinStatus = JoinTeamStatus.initial;
  Equipo? _selectedPredefinedTeam;

  late Future<List<Equipo>> _predefinedTeamsFuture;
  List<Equipo>? _cachedTeams;
  String? selectedBonoId; // Estado para el bono seleccionado

  late Future<Wallet> _walletFuture;
  late WalletService _walletService;

  int _currentImage = 0;
  late Future<Field> _fieldFuture;
  final StorageService storage = StorageService();
  List<Map<String, dynamic>> positions = [];
  final ValueNotifier<List<Map<String, dynamic>>> _positionsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  @override
  void initState() {
    super.initState();
    _selectedPredefinedTeam = null;
    _tabController = TabController(length: 3, vsync: this); // 3 pestañas
    _loadTeams();
    _setupPaymentListener();
    _fieldFuture = getFieldById(widget.match.fieldId!);
    _initializePositions();
    _predefinedTeamsFuture = _loadPredefinedTeams();
    _walletService = WalletService();
    _walletFuture = _walletService.getWallet();
  }

  Future<List<Equipo>> _loadPredefinedTeams() async {
    try {
      final teams = await MatchService().getPredefinedTeams();
      _cachedTeams = teams;
      return teams;
    } catch (e) {
      debugPrint('Error loading predefined teams: $e');
      rethrow;
    }
  }

  Future<void> _initializePositions() async {
    try {
      // Usar el gameType del partido (widget.match.gameType)
      final newPositions =
          PositionsConfig.getPositionsForFieldType(widget.match.gameType);
      setState(() {
        positions = newPositions;
        _positionsNotifier.value = newPositions;
      });
    } catch (e) {
      debugPrint('Error loading positions: $e');
      // En caso de error, usar posiciones por defecto para 'fut7'
      final defaultPositions = PositionsConfig.getPositionsForFieldType('fut7');
      setState(() {
        positions = defaultPositions;
        _positionsNotifier.value = defaultPositions;
      });
    }
  }

  Future<void> _loadTeams() async {
    _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
  }

  Future<Field> getFieldById(int fieldId) async {
    final url = Uri.parse('$baseUrl/fields/$fieldId');
    final token = await storage.getToken();
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return Field.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load field');
  }

  void _setupPaymentListener() {
    final Set<String> processedPaymentIds = {};

    _paymentSubscription = paymentStatusController.stream.listen((event) async {
      if (event is! Map<String, dynamic> || !event.containsKey('status')) {
        debugPrint('Evento inválido recibido: $event');
        return;
      }

      final status = event['status'] as PaymentStatus;
      final paymentId = event['paymentId']?.toString();

      debugPrint(
          'MatchDetailsScreen: Evento de pago recibido: $status, paymentId: $paymentId');

      if (!mounted) {
        debugPrint('MatchDetailsScreen: No está montado, ignorando evento');
        return;
      }

      switch (status) {
        case PaymentStatus.success:
        case PaymentStatus.approved:
          debugPrint('MatchDetailsScreen: Pago exitoso, actualizando UI');
          if (paymentId != null && !processedPaymentIds.contains(paymentId)) {
            processedPaymentIds.add(paymentId);
            await Future.delayed(Duration(seconds: 2));

            if (mounted) {
              setState(() {
                _joinStatus = JoinTeamStatus.success;
                _isLoading = true;
              });

              try {
                await _loadTeams();
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Te has unido al equipo exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error al recargar equipos: $e');
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Pago procesado, error al actualizar vista: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          }
          break;

        case PaymentStatus.failure:
          debugPrint('MatchDetailsScreen: Pago fallido');
          if (mounted) {
            setState(() => _joinStatus = JoinTeamStatus.error);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('El pago no se completó'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case PaymentStatus.pending:
          debugPrint('MatchDetailsScreen: Pago pendiente');
          if (mounted &&
              (paymentId == null || !processedPaymentIds.contains(paymentId))) {
            processedPaymentIds.add(paymentId ?? 'pending');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tu pago está en proceso de verificación'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          break;

        default:
          debugPrint('MatchDetailsScreen: Estado de pago desconocido');
          break;
      }
    });
  }

  @override
  void dispose() {
    _positionsNotifier.dispose();
    _paymentSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Devuelve `true` para indicar que la vista anterior debe recargarse
        Navigator.pop(context, true);
        return false; // Evita que el sistema maneje el retroceso automáticamente
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text('Detalles del Partido',
              style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareToWhatsApp(),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Color.fromARGB(255, 182, 190, 204),
            controller: _tabController,
            tabs: [
              Tab(text: 'INFORMACIÓN'),
              Tab(text: 'PARTICIPANTES'),
              Tab(text: 'COMENTARIOS'), // Nueva pestaña
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            MatchInfoTab(fieldFuture: _fieldFuture, match: widget.match),
            _buildTeamsTab(),
            CommentsTab(
                matchId: widget.match.id,
                matchCreatedAt:
                    widget.match.createdAt), // Pasar created_at del partido
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsTab() {
    return FutureBuilder<List<MatchTeam>>(
      future: _teamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
                SizedBox(height: 16),
                Text('Cargando equipos...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error cargando equipos',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Intente nuevamente',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, color: Colors.grey, size: 48),
                SizedBox(height: 16),
                Text('No hay equipos disponibles',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return FutureBuilder<bool>(
          future: _checkUserInTeam(snapshot.data!),
          builder: (context, userInTeamSnapshot) {
            if (userInTeamSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      color: Colors.blue, strokeWidth: 3));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) =>
                  _buildTeamSection(snapshot.data![index]),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamSection(MatchTeam team) {
    final Map<String, Color> colorMap = {
      'Rojo': Colors.red,
      'Azul': Colors.blue,
      'Verde': Colors.green,
      'Amarillo': Colors.yellow,
      'Blanco': Color(0xFFFFFFFF),
      'Negro': Color(0xFF000000),
      'Naranja': Colors.orange,
    };
    final Color teamColor = colorMap[team.color] ?? Colors.grey;
    final positions =
        PositionsConfig.getPositionsForFieldType(widget.match.gameType);
    final Map<String, TeamPlayer> playersByPosition = {
      for (var p in team.players)
        if (p.position != null) p.position!: p
    };

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
                backgroundColor: teamColor.withOpacity(0.2),
                child: Text(team.emoji ?? '⚽')),
            title: Text(team.name,
                style:
                    TextStyle(color: teamColor, fontWeight: FontWeight.bold)),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15)),
              child: Text('${team.playerCount}/${team.maxPlayers}',
                  style: TextStyle(
                      color: Colors.black.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
          Container(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildJoinButton(team, teamColor),
                ...positions.map((pos) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: _buildPlayerSlot(pos['name'],
                          playersByPosition[pos['name']], teamColor,
                          icon: pos['icon']),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareToWhatsApp() async {
    try {
      final field = await _fieldFuture;
      final date = DateFormat('dd/MM/yyyy').format(widget.match.scheduleDate);
      final deepLink = 'https://proyect.aftconta.mx/partido/${widget.match.id}';
      final message = '''
🌟 ¡Hola! FutPlay Te invita a un emocionante partido de fútbol! 🌟

🏆 *Partido*: ${widget.match.name}
📍 *Cancha*: Kevin - ${field.name}
🌎 *Ubicación*: Polideportivo
📅 *Fecha*: $date
⏰ *Horario*: ${widget.match.startTime} - ${widget.match.endTime}
⚽ *Tipo de juego*: ${widget.match.gameType == 'fut5' ? 'Fútbol 5' : 'Fútbol 7'}
💸 *Costo*: \$${widget.match.price}

¡Ven a disfrutar de una tarde llena de diversión, goles y buena compañía! No te lo pierdas, trae tu energía y únete al equipo. 🎉⚽

👉 *Detalles y registro*: $deepLink
''';

      final result = await Share.shareWithResult(message,
          subject: '¡Únete a nuestro partido de fútbol!');
      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('¡Partido compartido con éxito!'),
            backgroundColor: Colors.green));
      } else if (result.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Compartir cancelado'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red));
    }
  }

  Widget _buildPlayerSlot(String position, TeamPlayer? player, Color teamColor,
      {String? icon}) {
    final bool isAvailable = player == null;
    String? imageUrl = player?.user?.profileImage != null
        ? 'https://proyect.aftconta.mx/storage/${player!.user!.profileImage}'
        : null;

    debugPrint(
        'Renderizando slot - Position: $position, Player: ${player?.user?.name}');

    return GestureDetector(
      // Agregar GestureDetector para detectar el clic
      onTap: player != null && player.user?.id != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerProfilePage(
                    userId: player.user!.id,
                  ),
                ),
              ).then((_) {
                // Opcional: Si necesitas recargar algo al volver
                // setState(() => _loadTeams());
              });
            }
          : null, // No hacer nada si no hay jugador
      child: Container(
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
                        width: 2),
                    color: isAvailable ? Colors.grey.shade100 : Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        isAvailable ? Colors.grey.shade200 : Colors.grey[200],
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: isAvailable && icon != null
                        ? Image.asset(icon,
                            width: 24, height: 24, color: Colors.grey.shade400)
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
                  color: isAvailable ? Colors.grey.shade400 : Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(position ?? 'Sin posición',
                style: TextStyle(fontSize: 11, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUserInTeam(List<MatchTeam> teams) async {
    final currentUserId = await AuthService().getCurrentUserId();
    if (currentUserId == null) return false;
    return teams.any((team) => team.players.any(
        (player) => player.user?.id.toString() == currentUserId.toString()));
  }

  Widget _buildJoinButton(MatchTeam team, Color teamColor) {
    return FutureBuilder<List<MatchTeam>>(
      future: _teamsFuture,
      builder: (context, teamsSnapshot) {
        if (!teamsSnapshot.hasData) return SizedBox();
        return FutureBuilder<bool>(
          future: _checkUserInTeam(teamsSnapshot.data!),
          builder: (context, isInAnyTeamSnapshot) {
            if (!isInAnyTeamSnapshot.hasData) return SizedBox();
            if (isInAnyTeamSnapshot.data == true) {
              return FutureBuilder<bool>(
                future: _isUserInTeam(team),
                builder: (context, isInThisTeamSnapshot) {
                  if (isInThisTeamSnapshot.data == true) {}
                  return SizedBox();
                },
              );
            }
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
                            border: Border.all(color: teamColor, width: 2)),
                        child: Icon(Icons.add, color: teamColor),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Unirme', style: TextStyle(color: Colors.black)),
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

/*
  void _showLeaveTeamDialog(MatchTeam team) async {
    final bool isTeamCaptain = await MatchService().isUserTeamCaptain(team.id);
    final bool isPredefTeam =
        team.name != "Equipo 1" && team.name != "Equipo 2";

    if (!mounted) return;

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
            isTeamCaptain && isPredefTeam
                ? 'Retirar equipo'
                : 'Abandonar equipo',
            style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTeamCaptain && isPredefTeam
                  ? '¿Estás seguro que deseas retirar a todo el equipo del partido?'
                  : '¿Estás seguro que deseas abandonar el equipo?',
              style: TextStyle(color: Colors.black),
            ),
            if (isTeamCaptain && isPredefTeam) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Esta acción retirará a todos los miembros del equipo.',
                          style: TextStyle(
                              color: Colors.red, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    isTeamCaptain && isPredefTeam ? 'Retirar equipo' : 'Salir',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);
        if (isTeamCaptain && isPredefTeam) {
          await _leaveTeamAsGroup(team);
        } else {
          await _leaveTeam();
        }
        setState(() {
          _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTeamCaptain && isPredefTeam
                ? 'El equipo ha sido retirado exitosamente'
                : 'Has abandonado el equipo exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  */

  void _showJoinTeamDialog(MatchTeam team) {
    debugPrint('Game Type from match: ${widget.match.gameType}');
    final availablePositions =
        PositionsConfig.getPositionsForFieldType(widget.match.gameType);
    bool joinAsTeam = false;
    bool showRules = false;
    String? selectedPosition;
    bool normas1 = false;
    bool normas2 = false;
    bool normas3 = false;
    bool useWallet = false;

    // Obtener los bonos antes de abrir el diálogo
    Future<List<dynamic>> bonosFuture = MatchService().getUserBonos();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Seleccionar automáticamente el primer bono si no hay uno seleccionado
          bonosFuture.then((bonos) {
            if (bonos.isNotEmpty && selectedBonoId == null) {
              setDialogState(() {
                selectedBonoId = bonos.first['id'].toString();
              });
            }
          });

          return WillPopScope(
            onWillPop: () async => !_isLoading,
            child: Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          showRules ? 'Normas del evento' : 'Unirse al partido',
                          style: TextStyle(color: Colors.black)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!showRules) ...[
                          Row(
                            children: [
                              Text('Unirse como: ',
                                  style: TextStyle(color: Colors.black)),
                              DropdownButton<bool>(
                                value: joinAsTeam,
                                items: [
                                  DropdownMenuItem(
                                      value: false,
                                      child: Text('Individual',
                                          style:
                                              TextStyle(color: Colors.black))),
                                  DropdownMenuItem(
                                      value: true,
                                      child: Text('Equipo',
                                          style:
                                              TextStyle(color: Colors.black))),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    joinAsTeam = value ?? false;
                                    if (!joinAsTeam)
                                      _selectedPredefinedTeam = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          if (joinAsTeam)
                            FutureBuilder<List<Equipo>>(
                              future: _predefinedTeamsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  debugPrint(
                                      'Error en getPredefinedTeams: ${snapshot.error}');
                                  return Text('Error al cargar equipos');
                                }
                                final teams = _cachedTeams ?? [];
                                if (teams.isEmpty) {
                                  return Column(
                                    children: [
                                      Icon(Icons.sports_soccer,
                                          size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No tienes equipos disponibles',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600])),
                                      SizedBox(height: 8),
                                      Text(
                                          'Crea un equipo primero para poder inscribirlo',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey)),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: DropdownButton<Equipo>(
                                        hint: Text('Selecciona tu equipo'),
                                        value: _selectedPredefinedTeam,
                                        isExpanded: true,
                                        underline: SizedBox(),
                                        items: teams
                                            .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e.nombre)))
                                            .toList(),
                                        onChanged: (value) {
                                          setDialogState(() =>
                                              _selectedPredefinedTeam = value);
                                          setState(() =>
                                              _selectedPredefinedTeam = value);
                                          debugPrint(
                                              'Equipo seleccionado: ${value?.nombre}');
                                        },
                                      ),
                                    ),
                                    if (_selectedPredefinedTeam != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 16),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  setDialogState(
                                                      () => showRules = true);
                                                },
                                          child: Text('Inscribir Equipo',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            )
                          else ...[
                            // Mostrar bonos disponibles
                            FutureBuilder<List<dynamic>>(
                              future: bonosFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                if (snapshot.hasError) {
                                  return Text('Error al cargar bonos',
                                      style: TextStyle(color: Colors.red));
                                }

                                final bonos = snapshot.data ?? [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (bonos.isNotEmpty) ...[
                                      Text(
                                        'Usar un bono:',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<String>(
                                          hint: Text('Selecciona un bono'),
                                          value: selectedBonoId,
                                          isExpanded: true,
                                          underline: SizedBox(),
                                          items: bonos.map((bono) {
                                            return DropdownMenuItem<String>(
                                              value: bono['id'].toString(),
                                              child: Text(
                                                '${bono['bono']['titulo']} (Usos: ${bono['usos_disponibles'] ?? 'Ilimitados'})',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              selectedBonoId = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            // Opción para usar monedero
                            FutureBuilder<Wallet>(
                              future: _walletFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox();
                                }
                                if (snapshot.hasError) {
                                  return Text('Error al cargar monedero');
                                }
                                final wallet = snapshot.data!;
                                final matchPrice = widget.match.price;

                                if (wallet.balance == 0) {
                                  return SizedBox(); // No mostrar nada si el saldo es 0
                                }

                                if (wallet.balance >= matchPrice) {
                                  return CheckboxListTile(
                                    value: useWallet,
                                    onChanged: (value) {
                                      setDialogState(
                                          () => useWallet = value ?? false);
                                    },
                                    title: Text(
                                        'Usar monedero (\$${wallet.balance.toStringAsFixed(2)})',
                                        style: TextStyle(color: Colors.black)),
                                    subtitle: Text(
                                        'Costo: \$${matchPrice.toStringAsFixed(2)}',
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                } else if (wallet.balance > 1) {
                                  // Mostrar mensaje solo si el saldo es mayor a 1 y menor al precio
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Saldo insuficiente en el monedero (\$${wallet.balance.toStringAsFixed(2)}). Necesitas \$${matchPrice.toStringAsFixed(2)} para unirte o también puedes pagar con MercadoPago.',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  );
                                }
                                return SizedBox(); // No mostrar nada si el saldo es menor o igual a 1 pero mayor a 0
                              },
                            ),
                            SizedBox(height: 8),
                            Text('Selecciona tu posición:',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            SizedBox(height: 8),
                            ...availablePositions.map((position) {
                              bool isOccupied = team.players.any((player) =>
                                  player.position == position['name']);
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOccupied
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: isOccupied
                                          ? Colors.grey.shade300
                                          : Colors.blue.shade200,
                                      width: 1),
                                ),
                                child: ListTile(
                                  enabled: !isOccupied && !_isLoading,
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: isOccupied
                                            ? Colors.grey.shade200
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Image.asset(position['icon'],
                                        width: 24,
                                        height: 24,
                                        color: isOccupied || _isLoading
                                            ? Colors.grey.shade400
                                            : Colors.blue.shade700),
                                  ),
                                  title: Text(position['name'],
                                      style: TextStyle(
                                          color: isOccupied || _isLoading
                                              ? Colors.grey.shade400
                                              : Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: isOccupied
                                      ? Text('Posición ocupada',
                                          style: TextStyle(
                                              color: Colors.red.shade300,
                                              fontSize: 12))
                                      : Text('Disponible',
                                          style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 12)),
                                  onTap: (isOccupied || _isLoading)
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            selectedPosition = position['name'];
                                            showRules = true;
                                          });
                                        },
                                ),
                              );
                            }).toList(),
                            SizedBox(height: 16),
                          ],
                        ] else ...[
                          ListTile(
                            leading: Image.asset('assets/icons/estandar.png',
                                width: 100, height: 100),
                            title: Text('Normas del evento',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ),
                          CheckboxListTile(
                            value: normas1,
                            onChanged: (value) =>
                                setDialogState(() => normas1 = value ?? false),
                            title: Text('Estar 15 minutos antes del partido',
                                style: TextStyle(color: Colors.black)),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            value: normas2,
                            onChanged: (value) =>
                                setDialogState(() => normas2 = value ?? false),
                            title: Text(
                                'Reembolso al monedero en caso de cancelación',
                                style: TextStyle(color: Colors.black)),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            value: normas3,
                            onChanged: (value) =>
                                setDialogState(() => normas3 = value ?? false),
                            title: Text('Acepto las normas del evento',
                                style: TextStyle(color: Colors.black)),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12)),
                              onPressed: (normas1 && normas2 && normas3)
                                  ? () async {
                                      Navigator.pop(context);
                                      if (mounted) {
                                        await _handleJoinTeam(
                                          team,
                                          selectedPosition,
                                          joinAsTeam: joinAsTeam,
                                          predefinedTeam:
                                              _selectedPredefinedTeam,
                                          useBonoId: selectedBonoId,
                                          useWallet: useWallet,
                                        );
                                      }
                                    }
                                  : null,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Confirmar',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ],
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
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Procesando...',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
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

/*
  Future<void> _leaveTeamAsGroup(MatchTeam team) async {
    try {
      setState(() => _isLoading = true);
      await MatchService().leaveTeamAsGroup(team.id);
      setState(() {
        _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al retirar el equipo: $e'),
          backgroundColor: Colors.red));
    }
  }
  */

  Future<bool> _isUserInTeam(MatchTeam team) async {
    final currentUserId = await AuthService().getCurrentUserId();
    if (currentUserId == null) return false;
    return team.players.any(
        (player) => player.user?.id.toString() == currentUserId.toString());
  }

/*
  Future<void> _leaveTeam() async {
    try {
      setState(() => _isLoading = true);

      final currentUserId = await AuthService().getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      final teams = await MatchService().getTeamsForMatch(widget.match.id);
      final userTeam = teams.firstWhere(
        (team) => team.players.any(
            (player) => player.user?.id.toString() == currentUserId.toString()),
        orElse: () =>
            throw Exception('No estás en ningún equipo de este partido'),
      );

      final teamId = userTeam.id;
      debugPrint('Abandonando equipo con teamId: $teamId');

      // Validación de las 5 horas en el frontend
      final now = DateTime.now();
      final matchStartTime =
          DateTime.parse(widget.match.scheduleDate.toString());
      final hoursUntilStart = matchStartTime.difference(now).inHours;

      if (hoursUntilStart < 5) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Solo puedes abandonar el equipo con al menos 5 horas de antelación al inicio del partido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final response = await MatchService().leaveTeam(teamId);
      final jsonResponse =
          response is Map<String, dynamic> ? response : jsonDecode(response);

      if (mounted) {
        setState(() {
          _teamsFuture = MatchService().getTeamsForMatch(widget.match.id);
          _isLoading = false;
        });

        String message = jsonResponse['refunded'] == true
            ? 'Has abandonado el equipo y se te han reembolsado \$${jsonResponse['refunded_amount']} al monedero'
            : 'Has abandonado el equipo exitosamente';

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is Exception &&
            e.toString().contains('No estás en este equipo')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No estás registrado en este equipo'),
            backgroundColor: Colors.red,
          ));
        } else if (e is Exception && e.toString().contains('Trailing data')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error del servidor: Intente nuevamente más tarde'),
            backgroundColor: Colors.red,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al abandonar el equipo: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
      throw e;
    }
  }

  */

  Future<void> _handleJoinTeam(MatchTeam team, String? position,
      {required bool joinAsTeam,
      Equipo? predefinedTeam,
      String? useBonoId,
      bool useWallet = false}) async {
    try {
      setState(() => _isLoading = true);

      if (joinAsTeam && predefinedTeam != null) {
        // Registrar el equipo predefinido primero
        final response = await MatchService().registerPredefinedTeamForMatch(
            widget.match.id, predefinedTeam.id, team.id);
        debugPrint('Equipo inscrito: ${response['match_team_id']}');
        final registeredTeamId =
            int.parse(response['match_team_id'].toString());

        // Obtener los jugadores del MatchTeam recién registrado
        final teams = await MatchService().getTeamsForMatch(widget.match.id);
        final registeredTeam =
            teams.firstWhere((t) => t.id == registeredTeamId);

        if (mounted) {
          // Pasar los jugadores del MatchTeam registrado al diálogo
          await _showAssignPositionsDialog(
              registeredTeam, registeredTeam.players, predefinedTeam.id);
        }
      } else if (position != null) {
        if (widget.match.price > 0 && useBonoId == null && !useWallet) {
          // Pago con MercadoPago cuando no hay bono ni monedero
          if (mounted) {
            // Mostrar el diálogo de progreso
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => WillPopScope(
                onWillPop: () async => false, // Evitar cierre con botón atrás
                child: AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Procesando pago...',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
            );
          }
          try {
            final result = await MatchService().processTeamJoinPayment(team.id,
                position, widget.match.price, widget.match.id, context);
            if (mounted) {
              Navigator.of(context).pop();
              final status =
                  result['status'] as PaymentStatus? ?? PaymentStatus.failure;
              if (status == PaymentStatus.success ||
                  status == PaymentStatus.approved) {
                setState(() {
                  _joinStatus = JoinTeamStatus.success;
                  _loadTeams();
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Te has unido al equipo exitosamente'),
                  backgroundColor: Colors.green,
                ));
              } else if (status == PaymentStatus.pending) {
                setState(() => _joinStatus = JoinTeamStatus.processing);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Tu pago está siendo procesado'),
                  backgroundColor: Colors.orange,
                ));
              } else {
                setState(() => _joinStatus = JoinTeamStatus.error);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('El pago no se completó'),
                  backgroundColor: Colors.red,
                ));
              }
            }
          } catch (e) {
            debugPrint('Error al procesar el pago: $e');
            if (mounted) {
              Navigator.of(context).pop();
              setState(() => _joinStatus = JoinTeamStatus.error);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error al procesar el pago: $e'),
                backgroundColor: Colors.red,
              ));
            }
          }
        } else {
          // Unirse con bono, monedero o sin pago
          await MatchService().joinTeam(
            team.id,
            position,
            widget.match.id,
            useWallet: useWallet,
            useBonoId: useBonoId,
          );
          if (mounted) {
            setState(() {
              _joinStatus = JoinTeamStatus.success;
              _loadTeams();
              if (useWallet)
                _walletFuture =
                    _walletService.getWallet(); // Actualizar monedero
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  useBonoId != null
                      ? 'Bono utilizado, te has unido al equipo exitosamente'
                      : useWallet
                          ? 'Te has unido al equipo usando \$${widget.match.price} de tu monedero'
                          : 'Te has unido al equipo exitosamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => _joinStatus = JoinTeamStatus.error);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAssignPositionsDialog(
      MatchTeam team, List<TeamPlayer> players, int predefinedTeamId) async {
    final availablePositions =
        PositionsConfig.getPositionsForFieldType(widget.match.gameType);
    Map<int, String> selectedPositions = {};
    Set<String> takenPositions = {};

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text('Asignar Posiciones', style: TextStyle(color: Colors.black)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Asigna una posición a cada jugador del equipo',
                    style: TextStyle(fontSize: 14, color: Colors.black)),
                SizedBox(height: 16),
                ...players.map((player) {
                  List<String> availablePositionsForPlayer = availablePositions
                      .map((pos) => pos['name'] as String)
                      .where((posName) =>
                          !takenPositions.contains(posName) ||
                          selectedPositions[player.id] == posName)
                      .toList();

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: player.user?.profileImage !=
                                        null
                                    ? NetworkImage(
                                        'https://proyect.aftconta.mx/storage/${player.user!.profileImage}')
                                    : null,
                                child: player.user?.profileImage == null
                                    ? Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(player.user?.name ?? 'Jugador',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black)),
                                    if (selectedPositions[player.id] != null)
                                      Text(
                                          'Posición actual: ${selectedPositions[player.id]}',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Posición',
                              hintStyle: TextStyle(color: Colors.black),
                              border: OutlineInputBorder(),
                              helperText: availablePositionsForPlayer.isEmpty
                                  ? 'No hay posiciones disponibles'
                                  : 'Selecciona una posición',
                              helperStyle: TextStyle(
                                  color: availablePositionsForPlayer.isEmpty
                                      ? Colors.red
                                      : Colors.grey[600]),
                            ),
                            value: selectedPositions[player.id],
                            items: availablePositionsForPlayer.map((posName) {
                              final positionData = availablePositions
                                  .firstWhere((pos) => pos['name'] == posName);
                              return DropdownMenuItem<String>(
                                value: posName,
                                child: Row(
                                  children: [
                                    Image.asset(positionData['icon'] as String,
                                        width: 24,
                                        height: 24,
                                        color: Colors.grey[700]),
                                    SizedBox(width: 8),
                                    Text(posName),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setDialogState(() {
                                  if (selectedPositions[player.id] != null) {
                                    takenPositions
                                        .remove(selectedPositions[player.id]);
                                  }
                                  selectedPositions[player.id] = value;
                                  takenPositions.add(value);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (selectedPositions.length != players.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Asigna una posición a todos los jugadores'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (takenPositions.length != selectedPositions.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No pueden haber posiciones duplicadas'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Mostrar diálogo de progreso
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  // Actualizar posiciones
                  for (var entry in selectedPositions.entries) {
                    await MatchService()
                        .updatePlayerPosition(team.id, entry.key, entry.value);
                  }

                  // Finalizar registro
                  await MatchService().finalizeTeamRegistration(team.id);

                  // Cerrar el diálogo de progreso
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context); // Cerrar el diálogo de progreso
                  }

                  // Cerrar el diálogo principal
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context); // Cerrar el diálogo principal
                  }

                  // Actualizar la UI después de que todo termina
                  if (mounted) {
                    setState(() {
                      _loadTeams();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Posiciones asignadas correctamente'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  // Cerrar el diálogo de progreso en caso de error
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error al asignar posiciones: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: Text('Guardar Posiciones',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
