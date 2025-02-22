import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({Key? key}) : super(key: key);

  @override
  _StatsTabState createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final MatchService _matchService = MatchService();
    final AuthService authService = AuthService();

  Map<String, dynamic>? statsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

 Future<void> _loadStats() async {
  try {
    final userId = await authService.getCurrentUserId();
    if (userId == null) throw Exception('No se pudo obtener el ID del usuario');

    final response = await _matchService.getPlayerStats(userId);
    print('Stats Response: $response'); // Añadir este print
    setState(() {
      statsData = response;
      _isLoading = false;
    });
  } catch (e) {
    print('Error cargando estadísticas: $e');
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (statsData == null) {
      return const Center(child: Text('No se pudieron cargar las estadísticas'));
    }

    // Manejo de valores nulos y conversión de tipos
    final totalMatches = statsData!['stats']?['total_matches'] ?? 0;
    final mvpCount = statsData!['stats']?['mvp_count'] ?? 0;
    final averageRatingRaw = statsData!['stats']?['average_rating'] ?? '0.0';
    final averageRating = double.tryParse(averageRatingRaw.toString()) ?? 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Información',
              style: GoogleFonts.inter(fontSize: 24, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(totalMatches.toString(), 'Partidos'),
                _buildStatCard('N/A', 'Seguidores'), // No disponible en backend actual
                _buildStatCard(mvpCount.toString(), 'MVP'),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Evaluación',
              
              style: GoogleFonts.inter(fontSize: 24, color: Colors.black, ),
            ),
            const SizedBox(height: 16),
            _buildEvaluationRow('Promedio', averageRating, 5),
            _buildEvaluationRow('Nº. MVP', mvpCount, totalMatches, isCount: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationRow(String label, num value, num maxValue, {bool isCount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 16)),
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
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
          const SizedBox(width: 16),
          Text(
            isCount ? value.toString() : '${value.toStringAsFixed(1)}/$maxValue',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}