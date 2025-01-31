// lib/services/booking_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class BookingService {
  final AuthService _authService = AuthService();


Future<List<String>> getAvailableHoursx(int fieldId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId/available-hours?date=$date'),
        headers: await _authService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> hours = json.decode(response.body);
        return hours.map((hour) => hour.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting available hours: $e');
      return [];
    }
  }

  
Future<Map<String, dynamic>> createBooking({
    required int fieldId,
    required String date,
    required String startTime,
    int? playersNeeded,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: await _authService.getHeaders(),
        body: json.encode({
          'field_id': fieldId,
          'date': date,
          'start_time': startTime,
          'players_needed': playersNeeded,
        }),
      );

      debugPrint('Booking Status Code: ${response.statusCode}');
      debugPrint('Booking Response: ${response.body}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Reserva creada exitosamente'
        };
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Horario no disponible'
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Error al crear la reserva'
        };
      }
    } catch (e) {
      debugPrint('Error en la reserva: $e');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

}
