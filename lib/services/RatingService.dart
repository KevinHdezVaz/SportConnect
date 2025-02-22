import 'dart:convert';

import 'package:flutter/material.dart';
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

      debugPrint('RatingScreen Response status: ${response.statusCode}');
      debugPrint('RatingScreen Response body: ${response.body}');

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
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'ratings': ratings.map((rating) => {
            'user_id': rating['user_id'],
            'attitude_rating': rating['attitude_rating'], // Solo enviamos estas
            'participation_rating': rating['participation_rating'], // Solo enviamos estas
            'comment': rating['comment'],
          }).toList(),
          'mvp_vote': mvpId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al enviar calificaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en submitRatings: $e');
      throw e;
    }
  }
}