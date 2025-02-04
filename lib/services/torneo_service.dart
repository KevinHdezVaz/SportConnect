import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/utils/constantes.dart';
import '../model/Torneo.dart';

class TorneoService {
  Future<List<Torneo>> getTorneos() async {
    try {
      print('Intentando obtener torneos de: $baseUrl/torneos');
      final response = await http.get(Uri.parse('$baseUrl/torneos'));
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Verificar si la respuesta está envuelta en un objeto con 'data'
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'];
          print('Datos encontrados: ${data.length} torneos');
          return data.map((json) => Torneo.fromJson(json)).toList();
        } else {
          final List<dynamic> data = json.decode(response.body);
          print('Datos encontrados directamente: ${data.length} torneos');
          return data.map((json) => Torneo.fromJson(json)).toList();
        }
      } else {
        throw Exception('Error al cargar torneos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detallado: $e');
      throw Exception('Error de conexión: $e');
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
