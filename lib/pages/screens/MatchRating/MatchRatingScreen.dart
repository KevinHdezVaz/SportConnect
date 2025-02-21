import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  Map<String, dynamic>? _screenData;
  Map<int, int> _ratings = {};
  Map<int, String> _comments = {};
  int? _selectedMvp;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadRatingScreen();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRatingScreen() async {
    try {
      final data = await _ratingService.getRatingScreen(widget.matchId);
      debugPrint('Datos recibidos de getRatingScreen: $data');
      if (!mounted) return; // Evitar setState si el widget ya no existe
      setState(() {
        _screenData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando pantalla de calificación: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar Partido', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 16),
            Text(
              'Error al cargar: $_errorMessage',
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadRatingScreen();
              },
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_screenData == null || _screenData!['team_players'] == null) {
      return Center(
        child: Text('No se encontraron datos para calificar'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Califica a tus compañeros de equipo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
          ),
          SizedBox(height: 16),
          ...(_screenData!['team_players'] as List)
              .map((player) => _buildPlayerRatingCard(player))
              .toList(),
          SizedBox(height: 24),
          Text(
            'Selecciona al MVP del partido',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
          ),
          SizedBox(height: 16),
          _buildMvpSelection(),
          SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _submitRatings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Enviar Calificaciones',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRatingCard(Map<String, dynamic> player) {
    final userId = player['user']['id'] as int;
    final userName = player['user']['name'] as String? ?? 'Jugador desconocido';
    final profileImage = player['user']['profile_image'] as String?;

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.5),
          end: Offset.zero,
        ).animate(_animation),
        child: Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Efecto de hover o interacción
              setState(() {
                _ratings[userId] = _ratings[userId] ?? 0;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: profileImage != null
                            ? NetworkImage(
                                'https://proyect.aftconta.mx/storage/$profileImage')
                            : null,
                        child: profileImage == null ? Icon(Icons.person) : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          userName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Calificación:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < (_ratings[userId] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _ratings[userId] = index + 1;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Comentario (opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      _comments[userId] = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMvpSelection() {
    return Column(
      children: (_screenData!['team_players'] as List).map((player) {
        final userId = player['user']['id'] as int;
        final userName =
            player['user']['name'] as String? ?? 'Jugador desconocido';
        final profileImage = player['user']['profile_image'] as String?;

        return FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.5),
              end: Offset.zero,
            ).animate(_animation),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMvp = userId;
                });
              },
              child: Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedMvp == userId
                        ? Colors.blueAccent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: profileImage != null
                            ? NetworkImage(
                                'https://proyect.aftconta.mx/storage/$profileImage')
                            : null,
                        child: profileImage == null ? Icon(Icons.person) : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          userName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      if (_selectedMvp == userId)
                        Icon(
                          Icons.check_circle,
                          color: Colors.blueAccent,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitRatings() async {
    if (_selectedMvp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona un MVP')),
      );
      return;
    }

    try {
      final ratings = (_screenData!['team_players'] as List).map((player) {
        final userId = player['user']['id'] as int;
        return {
          'user_id': userId,
          'rating': _ratings[userId] ?? 0,
          'comment': _comments[userId] ?? '',
        };
      }).toList();

      await _ratingService.submitRatings(
        widget.matchId,
        ratings,
        _selectedMvp!,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificaciones enviadas exitosamente')),
      );
    } catch (e) {
      debugPrint('Error enviando calificaciones: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar calificaciones: $e')),
      );
    }
  }
}
