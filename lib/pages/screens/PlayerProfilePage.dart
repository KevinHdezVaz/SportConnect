import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';

class PlayerProfilePage extends StatefulWidget {
  final int userId;

  const PlayerProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _PlayerProfilePageState createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  final MatchService _matchService = MatchService();
  Map<String, dynamic>? playerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      final response = await _matchService.getPlayerStats(widget.userId);
      print('Player Data: $response');
      setState(() {
        playerData = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del jugador: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil del Jugador',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : playerData == null
              ? const Center(child: Text('No se pudieron cargar los datos'))
              : Stack(
                  children: [
            
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: playerData!['stats']['profile_image'] != null
                              ? NetworkImage(
                                  'https://proyect.aftconta.mx/storage/${playerData!['stats']['profile_image']}')
                              : const AssetImage('assets/no-profile-image.jpg')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.2), BlendMode.dstATop),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 120),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 80,
                                backgroundImage: playerData!['stats']
                                            ['profile_image'] !=
                                        null
                                    ? NetworkImage(
                                        'https://proyect.aftconta.mx/storage/${playerData!['stats']['profile_image']}')
                                    : const AssetImage(
                                            'assets/no-profile-image.jpg')
                                        as ImageProvider,
                              ),
                          SizedBox(height: 8),
Row(
  mainAxisAlignment: MainAxisAlignment.center,  
  children: [
     
    Text(
      playerData!['stats']['name'] ?? 'Jugador desconocido',
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),SizedBox(width: 10),

     if (playerData!['stats']['is_verified'] != true)
                                     const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
  ],
),
SizedBox(height: 16),
                               Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatButton(
                                      'Partidos',
                                      (playerData!['stats']['total_matches']
                                                  as int? ??
                                              0)
                                          .toString()),
                                  // Ejemplo, ajusta según backend
                                  _buildStatButton(
                                      'MVP',
                                      (playerData!['stats']['mvp_count']
                                                  as int? ??
                                              0)
                                          .toString()),
                                ],
                              ),
                              SizedBox(height: 20),
                              // Sección "Evaluación"
                              _buildSection('Evaluación', [
                                _buildEvaluationRow(
                                    'Global', _calculateAverageLevel() ?? 0, 5),
                                _buildEvaluationRow('Actitud',
                                    _calculateAverageAttitude() ?? 0, 5),
                                _buildEvaluationRow('Nivel.',
                                    _calculateAverageParticipation() ?? 0, 5),
                                _buildEvaluationRow(
                                    'N. MVP',
                                    playerData!['stats']['mvp_count'] as int? ??
                                        0,
                                    playerData!['stats']['total_matches']
                                            as int? ??
                                        0,
                                    isCount: true),
                              ]),
                              SizedBox(height: 16),
                              // Sección "Ficha técnica"
                              _buildSection('Ficha técnica', [
                                _buildTechField(
                                    'Posición:',
                                    playerData!['stats']['posicion'] ??
                                        'Sin especificar'),
                                _buildTechField(
                                    'Edad:',
                                    playerData!['stats']['age'] ??
                                        'Sin especificar'),
                              ]),
                              SizedBox(height: 16),
                              // Sección "Últimos partidos jugados"
                              _buildSection('Últimos partidos jugados', [
                                ..._getRecentMatchesList(),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Calcular el promedio de attitude_rating desde recent_matches
  int? _calculateAverageAttitude() {
    final recentMatches = playerData!['recent_matches'] as List<dynamic>? ?? [];
    if (recentMatches.isEmpty) return 0;

    double totalAttitude = 0;
    int count = 0;

    for (var match in recentMatches) {
      final attitude = (match['attitude_rating'] as num?)?.toDouble() ?? 0;
      if (attitude > 0) {
        // Solo consideramos valores mayores a 0
        totalAttitude += attitude;
        count++;
      }
    }

    if (count == 0) return 0;
    return totalAttitude.round() ~/
        count; // Redondeamos y aseguramos un entero entre 1 y 5
  }

  // Calcular el promedio de participation_rating desde recent_matches
  int? _calculateAverageParticipation() {
    final recentMatches = playerData!['recent_matches'] as List<dynamic>? ?? [];
    if (recentMatches.isEmpty) return 0;

    double totalParticipation = 0;
    int count = 0;

    for (var match in recentMatches) {
      final participation =
          (match['participation_rating'] as num?)?.toDouble() ?? 0;
      if (participation > 0) {
        // Solo consideramos valores mayores a 0
        totalParticipation += participation;
        count++;
      }
    }

    if (count == 0) return 0;
    return totalParticipation.round() ~/
        count; // Redondeamos y aseguramos un entero entre 1 y 5
  }

  // Calcular el promedio de nivel basado en attitude_rating y participation_rating de recent_matches
  int? _calculateAverageLevel() {
    final recentMatches = playerData!['recent_matches'] as List<dynamic>? ?? [];
    if (recentMatches.isEmpty) return 0;

    double totalAttitude = 0;
    double totalParticipation = 0;
    int count = 0;

    for (var match in recentMatches) {
      final attitude = (match['attitude_rating'] as num?)?.toDouble() ?? 0;
      final participation =
          (match['participation_rating'] as num?)?.toDouble() ?? 0;
      if (attitude > 0 || participation > 0) {
        // Solo consideramos partidos con calificaciones válidas
        totalAttitude += attitude;
        totalParticipation += participation;
        count++;
      }
    }

    if (count == 0) return 0;
    final average = ((totalAttitude + totalParticipation) / 2) / count;
    return average.round(); // Redondeamos al entero más cercano (1-5)
  }

  Widget _buildStatButton(String label, String count) {
    return Container(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 12,
        ),
        child: Column(
          children: [
            Text(count,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationRow(String label, int value, int maxValue,
      {bool isCount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text(label,
                    style:
                        GoogleFonts.inter(fontSize: 16, color: Colors.black)),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / maxValue,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
            isCount ? value.toString() : '$value/$maxValue',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTechField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  List<Widget> _getRecentMatchesList() {
    final recentMatches = playerData!['recent_matches'] as List<dynamic>? ?? [];
    if (recentMatches.isEmpty) {
      return [
        Text('No hay partidos recientes jugados.',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey))
      ];
    }
    return recentMatches.map((match) {
      final matchName = match['match_name'] as String? ?? 'Partido desconocido';
      final rating = (match['rating'] as num?)?.toInt() ?? 0;
      final comment = match['comment'] as String? ?? 'Sin comentario';
      final date = (match['created_at'] as String?)?.substring(0, 10) ??
          'Fecha desconocida'; // Formato YYYY-MM-DD
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              matchName,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            SizedBox(height: 4),
            Row(
              children: List.generate(
                  5,
                  (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20)),
            ),
            SizedBox(height: 4),
            Text(
              comment,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Fecha: $date',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            ),
            Divider(),
          ],
        ),
      );
    }).toList();
  }
}
