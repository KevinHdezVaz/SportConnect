// lib/services/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class BookingService {
  final AuthService _authService = AuthService();

  Future<bool> createBooking({
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

      if (response.statusCode == 201) {
        return true;
      }
      throw Exception(json.decode(response.body)['message']);
    } catch (e) {
      print('Error en la reserva: $e');
      return false;
    }
  }
}
