import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/EquipoPartidos.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';
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

  Future<void> processTeamJoinPayment(
      int teamId, String position, double price, int matchId) async {
    try {
      // Validaciones
      if (teamId <= 0) throw Exception('ID de equipo inválido');
      if (position.isEmpty) throw Exception('Posición requerida');
      if (price <= 0) throw Exception('Precio inválido');
      if (matchId <= 0) throw Exception('ID de partido inválido');

      final items = [
        OrderItem(
          title: "Inscripción a Partido",
          quantity: 1,
          unitPrice: price,
        )
      ];

      final userData = await AuthService().getProfile();
      debugPrint('Profile Data: $userData');

      // Simplifica la estructura de additionalData
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
      debugPrint('Payment Request Data: ${jsonEncode(additionalData)}');

      await PaymentService().procesarPago(
        navigatorKey.currentContext!,
        items,
        additionalData: additionalData,
      );
    } catch (e) {
      debugPrint('Error procesando pago: $e');
      throw Exception('Error al procesar el pago: $e');
    }
  }

  Future<List<MatchTeam>> getTeamsForMatch(int matchId) async {
    if (matchId <= 0) throw Exception('ID de partido inválido');

    try {
      debugPrint('Obteniendo equipos para partido ID: $matchId');

      final response = await http.get(
        Uri.parse('$baseUrl/matches/$matchId/teams'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> teamsData = data['teams'] ?? data['equipos'] ?? [];

        return teamsData.map((team) => MatchTeam.fromJson(team)).toList();
      } else {
        throw Exception('Error al cargar equipos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en getTeamsForMatch: $e');
      throw Exception('Error al obtener equipos: $e');
    }
  }

  Future<void> joinTeam(int teamId, String position) async {
    if (teamId <= 0) throw Exception('ID de equipo inválido');
    if (position.isEmpty) throw Exception('Posición requerida');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/matches/join-team'),
        headers: await getHeaders(),
        body: json.encode({
          'team_id': teamId,
          'position': position,
        }),
      );

      if (response.statusCode != 200) {
        final errorMessage = json.decode(response.body)['message'] ??
            'Error al unirse al equipo';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error al unirse al equipo: $e');
      throw Exception('Error al unirse al equipo: $e');
    }
  }

  Future<List<EquipoPartido>> getEquiposPartido(int matchId) async {
    if (matchId <= 0) throw Exception('ID de partido inválido');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matches/$matchId/teams'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['equipos'] as List)
            .map((equipo) => EquipoPartido.fromJson(equipo))
            .toList();
      } else {
        throw Exception('Error al cargar equipos');
      }
    } catch (e) {
      debugPrint('Error al obtener equipos del partido: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> joinMatch(int matchId) async {
    if (matchId <= 0) throw Exception('ID de partido inválido');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-matches/$matchId/join'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al unirse al partido');
      }
    } catch (e) {
      debugPrint('Error al unirse al partido: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }
}
