import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/services/RatingService.dart';

class MatchRatingScreen extends StatefulWidget {
  final int matchId;

  const MatchRatingScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _MatchRatingScreenState createState() => _MatchRatingScreenState();
}

class _MatchRatingScreenState extends State<MatchRatingScreen>
    with SingleTickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _screenData;
  Map<int, int> _attitudeRatings = {}; // Calificación de actitud
  Map<int, int> _participationRatings = {}; // Calificación de participación
  Map<int, String> _comments = {};
  int? _selectedMvp;
  String? _errorMessage;
  int? _currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRatingScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRatingScreen() async {
    try {
      // Obtener el ID del usuario desde almacenamiento local primero
      _currentUserId = await _authService.getUserIdFromStorage();

      // Si no está en almacenamiento, obtenerlo desde la API
      if (_currentUserId == null) {
        _currentUserId = await _authService.getCurrentUserId();
        if (_currentUserId != null) {
          await _authService
              .saveUserId(_currentUserId!); // Guardar para uso futuro
        }
      }

      if (_currentUserId == null) {
        throw Exception('No se pudo obtener el ID del usuario autenticado');
      }

      final data = await _ratingService.getRatingScreen(widget.matchId);
      print('Response from getRatingScreen: $data'); // Depuración
      if (!mounted) return;

      setState(() {
        _screenData = data is Map<String, dynamic> ? data : {};
        _isLoading = false;

        // Manejar team_players como List o Map con depuración detallada
        if (_screenData != null) {
          var teamPlayersRaw = _screenData!['team_players'];
          List<Map<String, dynamic>> filteredPlayers = [];

          if (teamPlayersRaw is List) {
            print('team_players is List: $teamPlayersRaw');
            filteredPlayers = teamPlayersRaw
                .where((player) {
                  if (player == null) {
                    print('Player is null');
                    return false;
                  }
                  if (player['user'] == null) {
                    print('Player user is null for: $player');
                    return false;
                  }
                  final userId = player['user']['id'];
                  print(
                      'Checking player user_id: $userId vs currentUserId: $_currentUserId');
                  return userId != null && userId != _currentUserId;
                })
                .cast<Map<String, dynamic>>()
                .toList();
          } else if (teamPlayersRaw is Map) {
            print('team_players is Map: $teamPlayersRaw');
            filteredPlayers = teamPlayersRaw.values
                .where((player) {
                  if (player == null) {
                    print('Player is null');
                    return false;
                  }
                  if (player['user'] == null) {
                    print('Player user is null for: $player');
                    return false;
                  }
                  final userId = player['user']['id'];
                  print(
                      'Checking player user_id: $userId vs currentUserId: $_currentUserId');
                  return userId != null && userId != _currentUserId;
                })
                .cast<Map<String, dynamic>>()
                .toList();
          } else {
            print('team_players is neither List nor Map: $teamPlayersRaw');
            filteredPlayers = [];
          }

          _screenData!['team_players'] = filteredPlayers;
          print('Filtered team_players: $filteredPlayers');
        } else {
          _screenData = {'team_players': []};
          print('No team_players found in _screenData or _screenData is null');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar los datos: $e';
      });
      print('Error in _loadRatingScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Regresar', style: GoogleFonts.inter(fontSize: 20)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.white],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    final teamPlayers = _screenData?['team_players'] as List? ?? [];
    if (teamPlayers.isEmpty) {
      return const Center(child: Text('No hay compañeros para calificar'));
    }

    return RefreshIndicator(
      onRefresh: _loadRatingScreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Califica a tus compañeros'),
            const SizedBox(height: 16),
            ...teamPlayers
                .map((player) => _buildPlayerRatingCard(player))
                .toList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Selecciona al MVP'),
            const SizedBox(height: 16),
            _buildMvpSelection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
      ),
    );
  }

  Widget _buildPlayerRatingCard(Map<String, dynamic> player) {
    if (player['user'] == null) {
      print('Player data is null or invalid: $player');
      return const SizedBox.shrink(); // Evitar errores si un player es inválido
    }

    final userId = player['user']['id'] as int? ?? 0;
    final userName = player['user']['name'] as String? ?? 'Jugador';
    final profileImage = player['user']['profile_image'] as String?;
    final attitudeRating = _attitudeRatings[userId] ?? 0;
    final participationRating = _participationRatings[userId] ?? 0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              elevation: 6,
              shadowColor: Colors.black26,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: attitudeRating == 0 && participationRating == 0
                      ? const Color.fromARGB(255, 234, 164, 73).withOpacity(0.5)
                      : Colors.green.withOpacity(0.7),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlayerHeader(userId, userName, profileImage),
                    const SizedBox(height: 16),
                    _buildRatingSection('Actitud', userId, _attitudeRatings),
                    const SizedBox(height: 8),
                    _buildRatingSection('Nivel', userId, _participationRatings),
                    const SizedBox(height: 16),
                    _buildCommentField(userId),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerHeader(int userId, String userName, String? profileImage) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: profileImage != null
              ? NetworkImage(
                  'https://proyect.aftconta.mx/storage/$profileImage')
              : null,
          backgroundColor: Colors.grey[300],
          child: profileImage == null
              ? const Icon(Icons.person, size: 28, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            userName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo[800],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(
      String label, int userId, Map<int, int> ratingsMap) {
    final rating = ratingsMap[userId] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => setState(() => ratingsMap[userId] = index + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_outline,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommentField(int userId) {
    return TextField(
      maxLines: 2,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Escribe un comentario (opcional)',
        hintStyle: TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(12),
      ),
      onChanged: (value) => _comments[userId] = value,
    );
  }

  Widget _buildMvpSelection() {
    final teamPlayers = _screenData?['team_players'] as List? ?? [];
    return Column(
      children: teamPlayers.map((player) {
        if (player['user'] == null) {
          print('Player data is null or invalid in MVP selection: $player');
          return const SizedBox
              .shrink(); // Evitar errores si un player es inválido
        }

        final userId = player['user']['id'] as int? ?? 0;
        final userName = player['user']['name'] as String? ?? 'Jugador';
        final profileImage = player['user']['profile_image'] as String?;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: _slideAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selectedMvp == userId
                          ? Colors.indigo
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => setState(() => _selectedMvp = userId),
                    leading: CircleAvatar(
                      backgroundImage: profileImage != null
                          ? NetworkImage(
                              'https://proyect.aftconta.mx/storage/$profileImage')
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: profileImage == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      userName,
                      style: TextStyle(
                        color: _selectedMvp == userId
                            ? Colors.indigo
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _selectedMvp == userId
                        ? const Icon(Icons.check_circle, color: Colors.indigo)
                        : null,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitRatings,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.blue,
          shadowColor: Colors.indigo.withOpacity(0.4),
        ),
        child: const Text(
          'Enviar Calificaciones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadRatingScreen();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  bool _areAllPlayersRated() {
    final teamPlayers = _screenData?['team_players'] as List? ?? [];
    if (teamPlayers.isEmpty) return false;
    return teamPlayers.every((player) {
      if (player['user'] == null) return false;
      final userId = player['user']['id'] as int? ?? 0;
      final attitudeRating = _attitudeRatings[userId] ?? 0;
      final participationRating = _participationRatings[userId] ?? 0;
      return attitudeRating >= 1 &&
          attitudeRating <= 5 &&
          participationRating >= 1 &&
          participationRating <= 5;
    });
  }

  Future<void> _submitRatings() async {
    if (!_areAllPlayersRated()) {
      _showSnackBar(
          'Por favor califica a todos tus compañeros en todas las categorías',
          Colors.red);
      return;
    }

    if (_selectedMvp == null) {
      _showSnackBar('Selecciona un MVP primero', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ratings = (_screenData?['team_players'] as List? ?? [])
          .map((player) {
            if (player['user'] == null) return null;
            final userId = player['user']['id'] as int? ?? 0;
            return {
              'user_id': userId,
              'attitude_rating':
                  _attitudeRatings[userId]!, // Solo enviamos estas
              'participation_rating':
                  _participationRatings[userId]!, // Solo enviamos estas
              'comment': _comments[userId] ?? '',
            };
          })
          .where((rating) => rating != null)
          .cast<Map<String, dynamic>>()
          .toList();

      await _ratingService.submitRatings(
          widget.matchId, ratings, _selectedMvp!);
      if (!mounted) return;

      // Devolver true para indicar que se calificó exitosamente
      Navigator.pop(context, true);
      _showSnackBar('Calificaciones enviadas con éxito', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error al enviar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: color == Colors.red
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }
}
