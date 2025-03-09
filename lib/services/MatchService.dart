import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class MatchService {
  final storage = StorageService();

  Future<Map<String, dynamic>> getPlayerStats(int userId) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/players/$userId/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al obtener estadísticas: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error en getPlayerStats: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getComments(int matchId) async {
    final token = await storage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/matches/$matchId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<Map<String, dynamic>> comments =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));
      // Asegúrate de que cada comentario incluye 'created_at' para mostrar la fecha
      return comments.map((comment) {
        if (!comment.containsKey('created_at')) {
          debugPrint('Warning: Comment missing created_at: $comment');
          comment['created_at'] =
              DateTime.now().toIso8601String(); // Fallback por defecto
        }
        return comment;
      }).toList();
    }
    throw Exception('Failed to load comments: ${response.body}');
  }

  Future<void> addComment(int matchId, String text) async {
    final token = await storage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/matches/$matchId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  Future<List<dynamic>> getTopMvpPlayers() async {
    final token = await storage.getToken();

    final url = Uri.parse('$baseUrl/top-mvp-players');

    print('mvp - Enviando solicitud GET a: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('mvp - Código de estado: ${response.statusCode}');
    print(
        'mvp - Respuesta completa: ${response.body}'); // 🔴 Muestra el JSON recibido

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print(
          'mvp - JSON decodificado: $data'); // 🔴 Muestra cómo se está interpretando el JSON

      return data['data'] ?? []; // Evita errores si 'data' es null
    } else {
      throw Exception(
          'Failed to load top MVP players. Status: ${response.statusCode}');
    }
  }

  Future<void> finalizeTeamRegistration(int teamId) async {
    try {
      final token = await storage.getToken();
      final url = Uri.parse('$baseUrl/match-teams/$teamId/finalize');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Finalize Team Response status: ${response.statusCode}');
      debugPrint('Finalize Team Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al finalizar inscripción: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en finalizeTeamRegistration: $e');
      throw Exception('Error al finalizar inscripción: $e');
    }
  }

  Future<Map<String, dynamic>> registerPredefinedTeamForMatch(int matchId,
      int predefinedTeamId, int targetTeamId // Agregar este parámetro
      ) async {
    debugPrint('⚽ Iniciando registro de equipo predefinido para partido...');
    debugPrint(
        '📊 Parámetros: matchId=$matchId, predefinedTeamId=$predefinedTeamId, targetTeamId=$targetTeamId');

    final url = Uri.parse('$baseUrl/match-teams/register-predefined-team');

    final token = await storage.getToken();

    final requestBody = {
      'match_id': matchId,
      'predefined_team_id': predefinedTeamId,
      'target_team_id': targetTeamId // Agregar este campo
    };
    debugPrint('📦 Body del request: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📡 Status code respuesta: ${response.statusCode}');
      debugPrint('📡 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        debugPrint('✅ Registro exitoso de equipo predefinido');
        return decodedResponse;
      } else {
        debugPrint('❌ Error en registro: Status ${response.statusCode}');
        debugPrint('❌ Detalle error: ${response.body}');
        throw Exception(
            'Failed to register predefined team: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 Excepción capturada: $e');
      throw Exception('Failed to register predefined team: $e');
    }
  }

  Future<List<Equipo>> getPredefinedTeams() async {
    final url = Uri.parse(
        '$baseUrl/equipos'); // Asumimos un endpoint para listar equipos
    final token = await StorageService().getToken();
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => Equipo.fromJson(e))
          .toList();
    }
    throw Exception('Error al cargar equipos predefinidos');
  }

  Future<void> updatePlayerPosition(
      int teamId, int playerId, String position) async {
    final url =
        Uri.parse('$baseUrl/match-teams/$teamId/players/$playerId/position');
    final token = await storage.getToken();

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'position': position,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update player position');
    }
  }

  Future<List<MathPartido>> getAvailableMatches(DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-matches?date=${date.toIso8601String()}'),
        headers: await getHeaders(),
      );

      // Agregar logs para debug
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['matches'] is List) {
          final List<dynamic> matchesJson = responseData['matches'];
          return matchesJson
              .map((json) {
                try {
                  return MathPartido.fromJson(json);
                } catch (e) {
                  print('Error parsing match: $e');
                  print('Problematic JSON: $json');
                  return null;
                }
              })
              .whereType<MathPartido>()
              .toList();
        } else {
          print('Matches is not a List: ${responseData['matches']}');
          return [];
        }
      } else {
        throw Exception('Error al cargar partidos: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error en getAvailableMatches: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error al obtener partidos: $e');
    }
  }

  Future<MathPartido> getMatchById(String matchId) async {
    if (matchId.isEmpty) throw Exception('ID de partido inválido');

    try {
      final url = Uri.parse('$baseUrl/matches/$matchId');
      debugPrint('Obteniendo partido con ID: $matchId');
      debugPrint('URL de la solicitud: $url');

      final response = await http.get(
        url,
        headers: await getHeaders(),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MathPartido.fromJson(jsonData);
      } else {
        throw Exception('Error al cargar el partido: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en getMatchById: $e');
      throw Exception('Error al obtener el partido: $e');
    }
  }

  Future<List<MathPartido>> getMatchesToRate() async {
    try {
      final token = await storage.getToken();
      debugPrint('Token para getMatchesToRate: $token');
      if (token == null) {
        debugPrint('No hay token disponible');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/matches/to-rate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('GetMatchesToRate Response status: ${response.statusCode}');
      debugPrint('GetMatchesToRate Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> matchesList = data['matches'] ?? [];
        debugPrint(
            'GetMatchesToRate Procesando ${matchesList.length} partidos');
        debugPrint('GetMatchesToRate Datos crudos: $matchesList');

        final matches = matchesList
            .map((matchJson) {
              try {
                final requiredFields = {
                  'id': matchJson['id'],
                  'name': matchJson['name'] ?? 'Sin nombre',
                  'schedule_date': matchJson['schedule_date'],
                  'start_time': matchJson['start_time'],
                  'end_time': matchJson['end_time'],
                };
                debugPrint(
                    'GetMatchesToRate Campos del partido: $requiredFields');
                return MathPartido.fromJson(matchJson);
              } catch (e) {
                debugPrint('GetMatchesToRate Error parseando partido: $e');
                debugPrint('GetMatchesToRate JSON problemático: $matchJson');
                return null;
              }
            })
            .where((match) => match != null)
            .cast<MathPartido>()
            .toList();

        debugPrint(
            'GetMatchesToRate Partidos parseados exitosamente: ${matches.length}');
        return matches;
      } else {
        debugPrint('GetMatchesToRate Estado no 200: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('GetMatchesToRate Error en getMatchesToRate: $e');
      debugPrint('GetMatchesToRate Stack trace: $stackTrace');
      return [];
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

  Future<void> joinTeam(int teamId, String position, int matchId,
      {bool useWallet = false, String? useBonoId}) async {
    try {
      final token = await storage.getToken();
      final url = Uri.parse('$baseUrl/match/join-team');
      final requestBody = {
        'match_id': matchId,
        'equipo_partido_id': teamId,
        'position': position,
        'use_wallet': useWallet,
        if (useBonoId != null) 'use_bono_id': useBonoId,
      };

      debugPrint('Request URL: $url');
      debugPrint('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Respuesta parseada: $jsonResponse');
        if (jsonResponse['used_wallet'] == true) {
          debugPrint(
              'Pago exitoso con monedero: \$${jsonResponse['amount_paid'] ?? 'Desconocido'}');
        } else if (jsonResponse['payment_method'] == 'bono') {
          debugPrint(
              'Bono utilizado: ${jsonResponse['message'] ?? 'Sin mensaje'}');
        } else {
          debugPrint('Unión al equipo exitosa sin pago');
        }
        return;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['message'] ?? 'Error desconocido al unirse al equipo');
      }
    } catch (e) {
      debugPrint('Error al unirse al equipo: $e');
      throw Exception('Error al unirse al equipo: $e');
    }
  }

  Future<bool> isUserTeamCaptain(int teamId) async {
    try {
      final url = Uri.parse('$baseUrl/match-teams/$teamId/is-captain');
      final token = await storage.getToken();
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_captain'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking captain status: $e');
      return false;
    }
  }

  Future<void> leaveTeamAsGroup(int teamId) async {
    final url = Uri.parse('$baseUrl/match-teams/$teamId/leave-group');
    final token = await storage.getToken();

    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave team as group');
    }
  }

  Future<dynamic> leaveTeam(int teamId) async {
    debugPrint('Intentando abandonar el equipo con teamId: $teamId');
    final token = await StorageService().getToken();
    final url = Uri.parse('$baseUrl/match-teams/$teamId/leave');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Request URL: $url');
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Ruta no encontrada: ${response.body}');
    } else {
      final error =
          jsonDecode(response.body)['error'] ?? 'Error al abandonar el equipo';
      throw Exception(
          'Error al abandonar el equipo: $error - Status ${response.statusCode}');
    }
  }

  // Actualiza este método en tu clase MatchService
  Future<Map<String, dynamic>> processTeamJoinPayment(int teamId,
      String position, double price, int matchId, BuildContext context) async {
    try {
      // Validaciones básicas
      if (teamId <= 0) throw Exception('ID de equipo inválido');
      if (position.isEmpty) throw Exception('Posición requerida');
      if (price <= 0) throw Exception('Precio inválido');
      if (matchId <= 0) throw Exception('ID de partido inválido');

      // Si el partido es gratuito, simplemente unirse sin pago
      if (price == 0) {
        await joinTeam(teamId, position, matchId);
        return {
          'status': 'success',
          'message': 'Te has unido al equipo exitosamente'
        };
      }

      // Obtener datos del usuario actual para el pago
      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();
      final userData = await authService.getProfile();

      // Crear los items para el pago
      final items = [
        OrderItem(
          title: "Inscripción a Partido",
          quantity: 1,
          unitPrice: price,
        )
      ];

      // Datos adicionales para el procesamiento del pago
      final additionalData = {
        'customer': {
          'name': userData['name'] ?? 'Usuario',
          'email': userData['email'] ?? 'usuario@ejemplo.com',
        },
        'reference_id': matchId,
        'team_id': teamId,
        'position': position,
      };

      // Usar el PaymentService existente para procesar el pago
      final paymentService = PaymentService();
      final result = await paymentService.procesarPago(
        context,
        items,
        additionalData: additionalData,
        type: 'match', // Usar 'match' como tipo para identificar
      );

      debugPrint('Resultado del pago: $result');
      return result;
    } catch (e) {
      debugPrint('Error procesando pago: $e');
      throw Exception('Error al procesar el pago: $e');
    }
  }

  Future<List<dynamic>> getUserBonos() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/bonos/mis-bonos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener bonos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en getUserBonos: $e');
      return [];
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
