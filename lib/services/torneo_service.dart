import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/utils/constantes.dart';
import '../model/Torneo.dart';

class TorneoService {
  void mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () {
            getTorneos();
          },
        ),
      ),
    );
  }

  Future<List<Torneo>> getTorneos() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/torneos'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData.containsKey('data')
            ? responseData['data']
            : json.decode(response.body);
        return data.map((json) => Torneo.fromJson(json)).toList();
      }
      throw Exception('Error del servidor');
    } catch (e) {
      throw Exception('Sin conexión');
    }
  }

  Future<Map<String, dynamic>> getTorneoDetails(int torneoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/torneos/$torneoId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return {
            'data': responseData['data'],
            'standings': responseData['standings'] ?? [],
            'rules': responseData['rules'] ?? [],
          };
        }
        throw Exception('Error en el formato de respuesta');
      } else {
        throw Exception(
            'Error al cargar detalles del torneo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detallado: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}
