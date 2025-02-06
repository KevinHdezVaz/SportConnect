import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/User.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class EquipoService {
  final storage = StorageService();

  Future<Equipo> crearEquipo({
    required String nombre,
    required String colorUniforme,
    File? logo,
    String? logoPredefinido,
  }) async {
    try {
      print('🚀 Iniciando petición HTTP para crear equipo...');
      print('Datos a enviar:');
      print('Nombre: $nombre');
      print('Color: $colorUniforme');
      print('Logo de galería: ${logo != null}');
      print('Logo predeterminado: ${logoPredefinido != null}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/equipos'),
      );

      request.fields['nombre'] = nombre;
      request.fields['color_uniforme'] = colorUniforme;

      // Solo se enviará un tipo de logo
      if (logo != null) {
        print('📁 Agregando logo de galería...');
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            logo.path,
          ),
        );
      } else if (logoPredefinido != null) {
        print('📁 Agregando logo predeterminado...');
        final byteData = await rootBundle.load(logoPredefinido);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_logo.png');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List());

        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            tempFile.path,
            filename: logoPredefinido.split('/').last,
          ),
        );
      }

      final headers = await _getHeaders();
      request.headers.addAll(headers);

      print('📤 Enviando petición...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Respuesta recibida:');
      print('Código de estado: ${response.statusCode}');
      print('Respuesta: ${response.body}');

      if (response.statusCode == 201) {
        final decodedData = json.decode(response.body);
        return Equipo.fromJson(decodedData['equipo']);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      print('❌ Error en el servicio:');
      print('Tipo de error: ${e.runtimeType}');
      print('Mensaje de error: $e');
      throw Exception('Error al crear equipo: $e');
    }
  }

  Future<void> inscribirseATorneo({
    required int equipoId,
    required int torneoId,
    File? comprobantePago,
  }) async {
    try {
      print('🚀 Iniciando inscripción a torneo...');
      print('Equipo ID: $equipoId');
      print('Torneo ID: $torneoId');

      // Corregir la URL para que coincida con la ruta en Laravel
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$baseUrl/equipos/$equipoId/torneos/inscribir'), // URL corregida
      );

      // Agregar el ID del torneo como campo
      request.fields['torneo_id'] = torneoId.toString();

      if (comprobantePago != null) {
        print('📄 Agregando comprobante de pago...');
        request.files.add(
          await http.MultipartFile.fromPath(
            'comprobante',
            comprobantePago.path,
          ),
        );
      }

      final headers = await _getHeaders();
      request.headers.addAll(headers);

      print('📤 Enviando petición...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Respuesta recibida:');
      print('Código de estado: ${response.statusCode}');
      print('Respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      print('❌ Error en inscripción:');
      print(e);
      throw Exception('Error al inscribirse al torneo: $e');
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

        return User.fromJson(
            responseData); // Asegúrate de que la estructura coincide
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [API ERROR] $e');
      throw Exception('Error al buscar usuario: $e');
    }
  }

  Future<void> invitarPorCodigo(
      {required int equipoId, required String codigo}) async {
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
