import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:user_auth_crudd10/services/storage_service.dart';

class AuthService {
  String baseUrl = 'http://192.168.0.20:8000/api';
  final storage = StorageService();

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

      if (response.statusCode != 200) {
        throw Exception('Error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        // await storage.saveUser(data['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error login: $e');
      return false;
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
      //   await storage.saveUser(data);
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

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? businessName,
    String? businessAddress,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: await getHeaders(),
        body: json.encode({
          'name': name,
          'phone': phone,
          'business_name': businessName,
          'business_address': businessAddress,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error actualizando perfil');
      }

      final data = json.decode(response.body);
      //   await storage.saveUser(data);
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? businessName,
    String? businessAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
          'business_name': businessName,
          'business_address': businessAddress,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}
