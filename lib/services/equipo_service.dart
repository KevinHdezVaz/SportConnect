import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/Miembro.dart';
import 'package:user_auth_crudd10/model/User.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class EquipoService {
  final storage = StorageService();

  Future<Equipo> crearEquipo({
    required String nombre,
    required String colorUniforme,
    File? logo,
    String? logoPredefinido,
    bool esAbierto = false, // Por defecto, es privado
    int plazasDisponibles =
        0, // Por defecto, 0 (no aplica para equipos privados)
  }) async {
    try {
      print('🚀 Iniciando petición HTTP para crear equipo...');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/equipos'),
      );

      request.fields['nombre'] = nombre;
      request.fields['color_uniforme'] = colorUniforme;
      request.fields['es_abierto'] = esAbierto ? '1' : '0'; // Enviar como 1 o 0
      request.fields['plazas_disponibles'] =
          plazasDisponibles.toString(); // Enviar plazas disponibles

      if (logo != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            logo.path,
          ),
        );
      } else if (logoPredefinido != null) {
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final decodedData = json.decode(response.body);
        return Equipo.fromJson(decodedData['equipo']);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Error al crear equipo: $e');
    }
  }

  // Inscribirse como individual
  Future<void> inscribirseIndividualATorneo({
    required int userId,
    required int torneoId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/torneos/$torneoId/inscribirse/individual'),
      headers: await _getHeaders(),
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message']);
    }
  }
// Agregar este método a la clase EquipoService

Future<void> inscribirEquipoEnTorneo({
  required int equipoId,
  required int torneoId,
  required List<Map<String, dynamic>> miembros,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/equipos/$equipoId/torneos/$torneoId/inscribir'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'miembros': miembros,
      }),
    );

    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      final errorMessage = responseData is Map && responseData.containsKey('message')
          ? responseData['message']
          : 'Error desconocido';
      throw Exception(errorMessage);
    }
  } catch (e) {
    debugPrint('❌ Error en inscribirEquipoEnTorneo: $e');
    throw Exception('Error al inscribir el equipo en el torneo: $e');
  }
}




  Future<void> unirseAEquipoAbierto({
    required int equipoId,
    required int userId,
    required String posicion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/equipos/$equipoId/unirse-abierto'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'posicion': posicion,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['message']);
      } 
    } catch (e) {
      throw Exception('Error al unirse al equipo: $e');
    }
  }

// Para solicitar unirse a un equipo privado
  Future<void> solicitarUnirseAEquipoPrivado(int equipoId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/equipos/$equipoId/solicitar-union'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Error al solicitar unirse al equipo privado: $e');
    }
  }

  
Future<List<Equipo>> obtenerEquiposDisponibles(int torneoId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/torneos/$torneoId/equipos-disponibles'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> rawData = json.decode(response.body);

      return rawData.map((data) {
        final Map<String, dynamic> equipoData = Map<String, dynamic>.from(data);
        return Equipo.fromJson(equipoData);
      }).toList();
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  } catch (e, stack) {
    print('Error en obtenerEquiposDisponibles: $e');
    print('Stack: $stack');
    rethrow;
  }



}




  Future<void> unirseAEquipo(
      int equipoId, int userId, BuildContext context) async {
    try {
      // 1️⃣ Obtener información del equipo
      final equipoResponse = await http.get(
        Uri.parse('$baseUrl/equipos/$equipoId'),
        headers: await _getHeaders(),
      );

      if (equipoResponse.statusCode != 200) {
        throw Exception('Error al obtener información del equipo');
      }

      final equipoData = json.decode(equipoResponse.body);
      final equipo = Equipo.fromJson(equipoData);
      debugPrint(
          'Equipo obtenido: ${equipoData.toString()}'); // Log para depuración

      // 2️⃣ Validar si hay plazas disponibles
      if (equipo.esAbierto && equipo.plazasDisponibles <= 0) {
        throw Exception('No hay plazas disponibles en este equipo');
      }

      // 3️⃣ Enviar solicitud para unirse al equipo
      final response = await http.post(
        Uri.parse('$baseUrl/equipos/$equipoId/unirse'),
        headers: await _getHeaders(),
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        final errorMessage =
            responseData is Map && responseData.containsKey('message')
                ? responseData['message']
                : 'Error desconocido';
        throw Exception(errorMessage);
      }

      debugPrint('Usuario unido con éxito. Actualizando plazas disponibles...');

      // 4️⃣ Si el equipo es abierto, actualizar plazas disponibles
      if (equipo.esAbierto) {
        final updatedPlazas = equipo.plazasDisponibles - 1;
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/equipos/$equipoId'),
          headers: await _getHeaders(),
          body: jsonEncode({'plazas_disponibles': updatedPlazas}),
        );

        if (updateResponse.statusCode != 200) {
          debugPrint(
              '⚠️ Advertencia: No se pudo actualizar las plazas disponibles.');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Te has unido al equipo exitosamente  EQUIPOSERVICE ESTA MAL AQUI')),
      );

      Navigator.pop(context);
    } catch (e, stacktrace) {
      debugPrint('❌ Error en unirseAEquipo: $e');
      debugPrint('Stacktrace: $stacktrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al unirse al equipo, ya estas en un equipo.')),
      );
    }
  }

  // Inscribir equipo en torneo
  Future<void> inscribirseATorneo({
    required int equipoId,
    required int torneoId,
    required List<int> jugadoresIds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/equipos/$equipoId/torneos/inscribir'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'torneo_id': torneoId,
        'jugadores_ids': jugadoresIds,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message']);
    }
  }

  // Obtener jugadores del equipo
  Future<List<Miembro>> obtenerJugadores(int equipoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/equipos/$equipoId/jugadores'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Miembro.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener jugadores');
    }
  }

  Future<User> buscarUsuarioPorCodigo({required String codigo}) async {
    final url = Uri.parse('$baseUrl/equipos/buscar-usuario/$codigo');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return User.fromJson(responseData);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al buscar usuario: $e');
    }
  }

  Future<void> invitarPorCodigo({
    required int equipoId,
    required String codigo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/equipos/$equipoId/invitar/codigo'),
        headers: await _getHeaders(),
        body: jsonEncode({'codigo': codigo}),
      );

      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Error al invitar por código: $e');
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
      final response = await http.get(
        Uri.parse('$baseUrl/equipos'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Equipo.fromJson(json)).toList();
      } else {
        throw Exception('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en getEquipos: $e');
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
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
