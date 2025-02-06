import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/User.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class EquipoService {
  final storage = StorageService();

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


Future<User> buscarUsuarioPorCodigo({required String codigo}) async {
  final url = Uri.parse('$baseUrl/equipos/buscar-usuario/$codigo');

  final headers = await _getHeaders();

  print('🔍 [API REQUEST] GET: $url');
  print('📄 Headers: $headers');

  try {
    final response = await http.get(url, headers: headers);

    print('✅ [API RESPONSE] Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('🛠 JSON Decoded: $responseData');

      return User.fromJson(responseData); // Asegúrate de que la estructura coincide
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ [API ERROR] $e');
    throw Exception('Error al buscar usuario: $e');
  }
}

 Future<void> invitarPorCodigo({
  required int equipoId, 
  required String codigo
}) async {
  print('Iniciando invitación por código...');
  print('Equipo ID: $equipoId, Código: $codigo');

  final url = Uri.parse('$baseUrl/equipos/$equipoId/invitar/codigo');
  print('URL: $url');

  final headers = await _getHeaders();
  print('Headers: $headers');

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'codigo': codigo}), // Codificar como JSON
    );

    print('Código de respuesta: ${response.statusCode}');
    print('Respuesta: ${response.body}');

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message']);
    }

    print('Invitación enviada con éxito');
  } catch (e) {
    print('Error al invitar por código: $e');
    rethrow;
  }
}

Future<int> getInvitacionesPendientesCount() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos/invitaciones/pendientes/count'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['count'];
    }
    return 0;
  } catch (e) {
    print('Error obteniendo conteo de invitaciones: $e');
    return 0;
  }
}


 Future<List<Equipo>> getInvitacionesPendientes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos/invitaciones/pendientes'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Equipo.fromJson(json)).toList();
    } else {
      throw Exception(json.decode(response.body)['message']);
    }
  }


  Future<void> aceptarInvitacion(int equipoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/equipos/$equipoId/aceptar'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message']);
    }
  }


  Future<void> rechazarInvitacion(int equipoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/equipos/$equipoId/rechazar'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message']);
    }
  }



 Future<List<Equipo>> getEquipos() async {
  try {
    print('🚀 Iniciando getEquipos...');
    final response = await http.get(
      Uri.parse('$baseUrl/equipos'),
      headers: await _getHeaders(),
    );
    
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Equipo.fromJson(json)).toList();
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Error en getEquipos: $e');
    rethrow;
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

  Future<void> eliminarMiembro(int equipoId, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/equipos/$equipoId/miembros/$userId'),
      headers: await _getHeaders(),
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
