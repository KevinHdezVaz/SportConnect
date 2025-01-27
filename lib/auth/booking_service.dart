import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<bool> createBooking({
    required int fieldId,
    required String date,
    required String startTime,
    int? playersNeeded,
  }) async {
    try {
      final token = await storage.getToken();
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

      print('Booking Status Code: ${response.statusCode}');
      print('Booking Response: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
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
