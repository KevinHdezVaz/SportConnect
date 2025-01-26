import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/field.dart';

class FieldService {
  final _authService = AuthService();
  Future<List<Field>> getFields() async {
    final response = await http.get(
      Uri.parse('${_authService.baseUrl}/fields'),
      headers: await _authService.getHeaders(),
    );

    print('Status code: ${response.statusCode}');
    print('Response body raw: ${response.body}');
    print('Response type: ${response.body.runtimeType}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print('Decoded type: ${decoded.runtimeType}');
      print('Decoded data: $decoded');

      final List<dynamic> data = decoded;
      return data.map((json) => Field.fromJson(json)).toList();
    }
    throw Exception('Error al cargar canchas');
  }

  Future<Map<String, dynamic>> checkAvailability(
      int fieldId, DateTime date) async {
    final response = await http.get(
      Uri.parse(
          '${_authService.baseUrl}/fields/$fieldId/availability?date=${date.toIso8601String()}'),
      headers: await _authService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al verificar disponibilidad');
  }
}
