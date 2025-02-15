import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/model/EquipoPartidos.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
 
 
class MatchService {
   final storage = StorageService();

  Future<List<MathPartido>> getAvailableMatches(DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-matches?date=${date.toIso8601String()}'),
        headers: await getHeaders(),
        
      );

      if (response.statusCode == 200) {
        final List<dynamic> matchesJson = json.decode(response.body)['matches'];
        return matchesJson.map((json) => MathPartido.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load matches');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

    Future<List<EquipoPartido>> getEquiposPartido(int matchId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matches/$matchId/teams'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['equipos'] as List).map((equipo) => 
          EquipoPartido.fromJson(equipo)
        ).toList();
      } else {
        throw Exception('Failed to load teams');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }


  Future<void> joinTeam({
    required int matchId,
    required int equipoPartidoId,
    required String position,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/match-players'),
        body: {
          'match_id': matchId.toString(),
          'equipo_partido_id': equipoPartidoId.toString(),
          'position': position,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to join team');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  Future<void> joinMatch(int matchId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-matches/$matchId/join'),
        headers: {
          'Accept': 'application/json',
          // Headers de autorización
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to join match');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}