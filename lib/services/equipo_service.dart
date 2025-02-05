import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class EquipoService {
  final storage = StorageService();

  // lib/services/equipo_service.dart
  Future<Equipo> crearEquipo({
    required String nombre,
    required String colorUniforme,
    File? logo,
  }) async {
    try {
      print('🚀 Iniciando petición HTTP para crear equipo...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/equipos'),
      );

      request.fields['nombre'] = nombre;
      request.fields['color_uniforme'] = colorUniforme;

      if (logo != null) {
        print('📁 Agregando archivo de logo...');
        print('Path del logo: ${logo.path}');
        request.files.add(
          await http.MultipartFile.fromPath('logo', logo.path),
        );
      }

      // Importante: quitar Content-Type para multipart
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      print('📤 Enviando petición...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('📥 Respuesta recibida:');
      print('Código de estado: ${response.statusCode}');
      print('Respuesta: $responseData');

      if (response.statusCode == 201) {
        final decodedData = json.decode(responseData);
        return Equipo.fromJson(decodedData['equipo']);
      } else {
        throw Exception(json.decode(responseData)['message']);
      }
    } catch (e) {
      print('❌ Error en el servicio:');
      print('Tipo de error: ${e.runtimeType}');
      print('Mensaje de error: $e');
      throw Exception('Error al crear equipo: $e');
    }
  }

  Future<List<Equipo>> getEquipos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Equipo.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar equipos');
    }
  }

  Future<void> invitarMiembro(int equipoId, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/equipos/$equipoId/invitar'),
      headers: await _getHeaders(),
      body: {'email': email},
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message']);
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
