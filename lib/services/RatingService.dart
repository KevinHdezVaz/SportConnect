import 'dart:convert';

import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

class RatingService {
   final StorageService storage = StorageService();

  Future<Map<String, dynamic>> getRatingScreen(int matchId) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/matches/$matchId/rating'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar la pantalla de calificación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> submitRatings(int matchId, List<Map<String, dynamic>> ratings, int mvpId) async {
    try {
      final token = await storage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/matches/$matchId/rating'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ratings': ratings,
          'mvp_vote': mvpId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al enviar calificaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}