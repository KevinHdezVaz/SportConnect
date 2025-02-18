import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/EquipoPartidos.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class MatchService {
  final storage = StorageService();

  // Obtener partidos disponibles
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
        throw Exception('Error al cargar partidos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en getAvailableMatches: $e');
      throw Exception('Error al obtener partidos: $e');
    }
  }

Future<List<MatchTeam>> getTeamsForMatch(int matchId) async {
  if (matchId <= 0) throw Exception('ID de partido inválido');
  
  try {
    final url = Uri.parse('$baseUrl/matches/$matchId/teams');
    debugPrint('Obteniendo equipos para partido ID: $matchId');
    debugPrint('URL de la solicitud: $url');

    final response = await http.get(
      url,
      headers: await getHeaders(),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> teamsData = data['equipos'] ?? [];
      try {
        return teamsData.map((team) => MatchTeam.fromJson(team)).toList();
      } catch (e) {
        debugPrint('Error parseando equipos: $e');
        rethrow;
      }
    } else {
      throw Exception('Error al cargar equipos: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error en getTeamsForMatch: $e');
    rethrow;
  }
}
  // Unirse a un equipo
  Future<void> joinTeam(int teamId, String position, int matchId) async {
    if (teamId <= 0) throw Exception('ID de equipo inválido');
    if (position.isEmpty) throw Exception('Posición requerida');
    if (matchId <= 0) throw Exception('ID de partido inválido');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/matches/join-team'),
        headers: await getHeaders(),
        body: json.encode({
          'match_id': matchId,
          'equipo_partido_id': teamId,
          'position': position,
        }),
      );

      debugPrint('Request URL: ${Uri.parse('$baseUrl/matches/join-team')}');
      debugPrint('Request body: ${json.encode({
        'match_id': matchId,
        'equipo_partido_id': teamId,
        'position': position,
      })}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 422) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error de validación');
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 
            'Error al unirse al equipo';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error al unirse al equipo: $e');
      throw Exception('Error al unirse al equipo: $e');
    }
  }

  // Procesar pago y unirse al equipo
  Future<void> processTeamJoinPayment(
      int teamId, String position, double price, int matchId) async {
    try {
      // Validaciones básicas
      if (teamId <= 0) throw Exception('ID de equipo inválido');
      if (position.isEmpty) throw Exception('Posición requerida');
      if (price <= 0) throw Exception('Precio inválido');
      if (matchId <= 0) throw Exception('ID de partido inválido');

      // Por ahora, solo unirse al equipo
      await joinTeam(teamId, position, matchId);

      /* Implementación futura del sistema de pago
      final items = [
        OrderItem(
          title: "Inscripción a Partido",
          quantity: 1,
          unitPrice: price,
        )
      ];

      final userData = await AuthService().getProfile();
      final additionalData = {
        'payer': {
          'name': userData['name'] ?? 'Usuario',
          'email': userData['email'] ?? 'usuario@ejemplo.com',
        },
        'team_id': teamId,
        'position': position,
        'match_id': matchId,
        'type': 'team_join'
      };

      final paymentService = PaymentService();
      final result = await paymentService.createPayment(items, additionalData);
      */
    } catch (e) {
      debugPrint('Error procesando pago: $e');
      throw Exception('Error al procesar el pago: $e');
    }
  }

  // Unirse a un partido
  Future<void> joinMatch(int matchId) async {
    if (matchId <= 0) throw Exception('ID de partido inválido');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-matches/$matchId/join'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorMessage = json.decode(response.body)['message'] ?? 
            'Error al unirse al partido';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error al unirse al partido: $e');
      throw Exception('Error al unirse al partido: $e');
    }
  }

  // Headers para las peticiones
  Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }
}