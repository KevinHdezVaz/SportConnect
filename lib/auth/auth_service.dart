import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class AuthService {
  final storage = StorageService();

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? postalCode,
    String? posicion,
    File? profileImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/profile');

      // Crear el mapa de datos
      Map<String, String> fields = {};
      if (name != null) fields['name'] = name;
      if (phone != null) fields['phone'] = phone;
      if (postalCode != null) fields['codigo_postal'] = postalCode;
      if (posicion != null) fields['posicion'] = posicion;

      // Obtener headers
      final headers = await getHeaders();

      // Si hay imagen, usar MultipartRequest
      if (profileImage != null) {
        final request = http.MultipartRequest('POST', uri) // Cambiar a POST
          ..headers.addAll(headers)
          ..fields.addAll(fields);

        final fileStream = http.ByteStream(profileImage.openRead());
        final length = await profileImage.length();
        final multipartFile = http.MultipartFile(
          'profile_image',
          fileStream,
          length,
          filename: profileImage.path.split('/').last,
        );
        request.files.add(multipartFile);

        // Agregar _method field para simular PUT
        request.fields['_method'] = 'PUT';

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('Respuesta: ${response.body}');
        return response.statusCode == 200;
      }
      // Si no hay imagen, usar PUT normal
      else {
        final response = await http.put(
          uri,
          headers: headers,
          body: json.encode(fields),
        );

        print('Respuesta: ${response.body}');
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error actualizando perfil: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password,
      {double? latitude, double? longitude}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        if (data['user'] != null && data['user']['id'] != null) {
          await saveUserId(data['user']['id']);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error login: $e');
      return false;
    }
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-device-token'),
        headers: await getHeaders(),
        body: json.encode({'device_token': token}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error actualizando token');
      }
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error obteniendo perfil');
      }

      final data = json.decode(response.body);
      print('Profile Data: $data'); // Agrega esto para depurar
      return data;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await getHeaders(),
      );
      await storage.removeToken();
    } catch (e) {
      throw Exception('Error al cerrar sesión');
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      return json.decode(response.body)['exists'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-phone'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );
      return json.decode(response.body)['exists'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginWithGoogle(String? idToken) async {
    if (idToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      print('Status code: ${response.statusCode}');
      print('Respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      final profileData = await getProfile();
      return profileData[
          'id']; // Asumiendo que el perfil incluye el 'id' del usuario
    } catch (e) {
      print('Error obteniendo ID del usuario: $e');
      return null;
    }
  }

  Future<void> saveUserId(int id) async {
    await storage.saveString('user_id', id.toString());
  }

  Future<int?> getUserIdFromStorage() async {
    final idStr = await storage.getString('user_id');
    return idStr != null ? int.parse(idStr) : null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String codigpostal,
    required String phone,
    File? profileImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/register');
      final request = http.MultipartRequest('POST', uri);

      // Imprimir URL y cuerpo de la solicitud
      print('Request URL: $baseUrl/register');
      print('Request body: ${json.encode({
            'name': name,
            'email': email,
            'codigo_postal': codigpostal,
            'password': password,
            'phone': phone,
          })}');

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['codigo_postal'] = codigpostal;
      request.fields['phone'] = phone;

      if (profileImage != null) {
        print('Profile image path: ${profileImage.path}');
        print('File size: ${await profileImage.length()} bytes');

        final fileStream = http.ByteStream(profileImage.openRead());
        final length = await profileImage.length();
        final multipartFile = http.MultipartFile(
          'profile_image',
          fileStream,
          length,
          filename: profileImage.path.split('/').last,
        );
        request.files.add(multipartFile);
        print('Profile image added to request');
      }

      // Enviar solicitud
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Imprimir detalles de la respuesta
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error: ${response.statusCode}');
      }

      final data = json.decode(responseBody);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error login: $e');
      return false;
    }
  }
}
