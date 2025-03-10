import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/booking.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class BookingService {
  final StorageService storage = StorageService();

  Future<Field> getFieldDetails(int fieldId) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Field.fromJson(data);
      } else {
        throw Exception(
            'Error al obtener los detalles del campo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting field details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    try {
      final token = await storage.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$reservationId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': 'Usuario canceló la reserva'}),
      );

      debugPrint('Cancel Booking Status Code: ${response.statusCode}');
      debugPrint('Cancel Booking Response: ${response.body}');

      try {
        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Reserva cancelada exitosamente',
            'refunded_amount': responseData['refunded_amount'],
            'booking': responseData['booking']
          };
        } else if (response.statusCode == 400 &&
            responseData['message'] == 'La reserva ya está cancelada') {
          return {'success': false, 'message': responseData['message']};
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Error al cancelar la reserva'
          };
        }
      } catch (e) {
        debugPrint('Error al decodificar JSON: $e');
        return {
          'success': false,
          'message': 'Error en el servidor. Por favor, inténtalo más tarde.'
        };
      }
    } catch (e) {
      debugPrint('Error al cancelar la reserva: $e');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  Future<List<String>> getAvailableHours(int fieldId, String date) async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId/available-hours?date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Response status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        debugPrint("Decoded data type: ${decodedData.runtimeType}");
        debugPrint("Decoded data: $decodedData");

        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('available_hours')) {
          final availableHours = decodedData['available_hours'];
          if (availableHours is List) {
            return availableHours.map((hour) => hour.toString()).toList();
          } else {
            debugPrint('Error: available_hours no es una lista');
            return [];
          }
        } else {
          debugPrint('Error: la respuesta no tiene el formato esperado');
          return [];
        }
      } else {
        debugPrint('Error: código de estado ${response.statusCode}');
        throw Exception(
            'Error al obtener horarios disponibles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting available hours: $e');
      throw Exception('Error al obtener horarios disponibles: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int fieldId,
    required String date,
    required String startTime,
    int? playersNeeded,
    bool useWallet = false,
    String? paymentId,
    String? orderId,
  }) async {
    try {
      final token = await storage.getToken();

      final Map<String, dynamic> requestData = {
        'field_id': fieldId,
        'date': date,
        'start_time': startTime,
        'players_needed': playersNeeded,
        'use_wallet': useWallet,
      };

      if (paymentId != null) {
        requestData['payment_id'] = paymentId;
      }

      if (orderId != null) {
        requestData['order_id'] = orderId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      debugPrint('Booking Status Code: ${response.statusCode}');
      debugPrint('Booking Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': response.statusCode == 200
              ? 'La reserva ya fue procesada anteriormente'
              : 'Reserva creada exitosamente'
        };
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        if (paymentId != null &&
            responseData['message'] == 'Horario no disponible') {
          final verifyResponse = await http.get(
            Uri.parse('$baseUrl/bookings/check-payment/$paymentId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (verifyResponse.statusCode == 200) {
            final verifyData = json.decode(verifyResponse.body);
            if (verifyData['exists'] == true) {
              return {
                'success': true,
                'message': 'La reserva ya fue procesada exitosamente',
                'booking_id': verifyData['booking_id']
              };
            }
          }
        }

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

      debugPrint(
          'Active Reservations - Código de estado: ${response.statusCode}');
      debugPrint('Active Reservations - Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        debugPrint('Active Reservations - Datos recibidos: $data');

        final activeBookings =
            data.map((item) => Booking.fromJson(item)).toList();

        debugPrint('Active Reservations - Reservas activas: $activeBookings');
        return activeBookings;
      } else {
        throw Exception(
            'No se pudieron cargar las reservas activas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener reservas activas: $e');
      rethrow;
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

      debugPrint('Código de estado: ${response.statusCode}');
      debugPrint('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        debugPrint('Datos de historial recibidos: $data');

        final historicalBookings =
            data.map((item) => Booking.fromJson(item)).toList();

        debugPrint('Reservas históricas: $historicalBookings');
        return historicalBookings;
      } else {
        throw Exception(
            'No se pudo cargar el historial de reservas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener historial de reservas: $e');
      rethrow;
    }
  }

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
      debugPrint('Error al obtener todas las reservas: $e');
      rethrow;
    }
  }
}
