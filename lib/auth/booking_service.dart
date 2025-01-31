import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/booking.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class BookingService {
  final StorageService storage = StorageService();

  // Método para cancelar reserva
  Future<bool> cancelReservation(String reservationId) async {
    try {
      final token = await storage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/cancelReservation/$reservationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Reserva cancelada exitosamente');
        return true;
      } else {
        print(
            'Error al cancelar la reserva. Código de estado: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error al cancelar la reserva: $e');
      return false;
    }
  }

  Future<List<String>> getAvailableHours(int fieldId, String date) async {
    try {
      debugPrint('Requesting available hours for field $fieldId on date $date');
      final Uri url =
          Uri.parse('$baseUrl/fields/$fieldId/available-hours?date=$date');

      final response = await http.get(
        url,
        headers: await AuthService().getHeaders(),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        return decodedData.map((hour) => hour.toString()).toList();
      } else {
        debugPrint('Error en la respuesta: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting available hours: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error al obtener horarios disponibles: $e');
    }
  }

  String _getDayOfWeek(String date) {
    // Parsea la fecha en formato String a un objeto DateTime
    final DateTime dateTime = DateTime.parse(date);

    // Usa el paquete `intl` para obtener el día de la semana en formato largo (por ejemplo, "Monday")
    final String dayName = DateFormat('EEEE').format(dateTime);

    // Convierte el nombre del día a minúsculas y en inglés para que coincida con las claves del JSON
    switch (dayName.toLowerCase()) {
      case 'monday':
        return 'monday';
      case 'tuesday':
        return 'tuesday';
      case 'wednesday':
        return 'wednesday';
      case 'thursday':
        return 'thursday';
      case 'friday':
        return 'friday';
      case 'saturday':
        return 'saturday';
      case 'sunday':
        return 'sunday';
      default:
        throw Exception('Día de la semana no válido');
    }
  }

  Future<List<Booking>> getActiveReservations() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/active-reservations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Active Reservations - Código de estado: ${response.statusCode}');
      print('Active Reservations - Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Active Reservations - Datos recibidos: $data');

        final activeBookings =
            data.map((item) => Booking.fromJson(item)).toList();

        print('Active Reservations - Reservas activas: $activeBookings');
        return activeBookings;
      } else {
        throw Exception(
            'No se pudieron cargar las reservas activas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener reservas activas: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int fieldId,
    required String date,
    required String startTime,
    int? playersNeeded,
  }) async {
    try {
      final token = await storage.getToken();
      debugPrint("Token: $token");

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'field_id': fieldId,
          'date': date,
          'start_time': startTime,
          'players_needed': playersNeeded,
        }),
      );

      debugPrint("Response status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Reserva creada exitosamente'};
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Horario no disponible'
        };
      } else {
        return {'success': false, 'message': 'Error al crear la reserva'};
      }
    } catch (e) {
      print('Error en la reserva: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Booking>> getReservationHistory() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reservation-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Código de estado: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Datos de historial recibidos: $data');

        // Mapea directamente sin filtro adicional
        final historicalBookings =
            data.map((item) => Booking.fromJson(item)).toList();

        print('Reservas históricas: $historicalBookings');
        return historicalBookings;
      } else {
        throw Exception(
            'No se pudo cargar el historial de reservas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener historial de reservas: $e');
      rethrow;
    }
  }

  // Método para obtener todas las reservas
  Future<List<Booking>> getAllReservations() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => Booking.fromJson(item)).toList();
      } else {
        throw Exception(
            'No se pudieron cargar las reservas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener todas las reservas: $e');
      rethrow;
    }
  }
}
