// lib/screens/match_rating_screen.dart
import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/services/RatingService.dart';

class MatchRatingScreen extends StatefulWidget {
  final int matchId;

  const MatchRatingScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _MatchRatingScreenState createState() => _MatchRatingScreenState();
}

class _MatchRatingScreenState extends State<MatchRatingScreen> {
  final RatingService _ratingService = RatingService();
  bool _isLoading = true;
  Map<String, dynamic>? _screenData;
  Map<int, int> _ratings = {};
  Map<int, String> _comments = {};
  int? _selectedMvp;

  @override
  void initState() {
    super.initState();
    _loadRatingScreen();
  }

  Future<void> _loadRatingScreen() async {
    try {
      final data = await _ratingService.getRatingScreen(widget.matchId);
      setState(() {
        _screenData = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Calificar Partido')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Calificar Partido')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Califica a tus compañeros de equipo',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            ...(_screenData?['team_players'] as List).map((player) => 
              _buildPlayerRatingCard(player)
            ).toList(),
            SizedBox(height: 24),
            Text(
              'Selecciona al MVP del partido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            _buildMvpSelection(),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitRatings,
                child: Text('Enviar Calificaciones'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRatingCard(Map<String, dynamic> player) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://proyect.aftconta.mx/storage/${player['user']['profile_image']}'
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  player['user']['name'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Calificación:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => 
                IconButton(
                  icon: Icon(
                    index < (_ratings[player['user']['id']] ?? 0) 
                      ? Icons.star 
                      : Icons.star_border
                  ),
                  onPressed: () {
                    setState(() {
                      _ratings[player['user']['id']] = index + 1;
                    });
                  },
                ),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _comments[player['user']['id']] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMvpSelection() {
    return Column(
      children: (_screenData?['team_players'] as List).map((player) => 
        RadioListTile<int>(
          title: Text(player['user']['name']),
          value: player['user']['id'],
          groupValue: _selectedMvp,
          onChanged: (value) {
            setState(() {
              _selectedMvp = value;
            });
          },
        ),
      ).toList(),
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
      final ratings = (_screenData?['team_players'] as List).map((player) {
        final userId = player['user']['id'];
        return {
          'user_id': userId,
          'rating': _ratings[userId] ?? 0,
          'comment': _comments[userId],
        };
      }).toList();

      await _ratingService.submitRatings(
        widget.matchId, 
        ratings, 
        _selectedMvp!
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificaciones enviadas exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar calificaciones: $e')),
      );
    }
  }
}