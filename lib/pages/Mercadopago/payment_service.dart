import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class PaymentService {
  final storage = StorageService();

  Future<void> procesarPago(List<OrderItem> items) async {
    try {
      final token = await storage.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/payments/create-preference'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'items': items.map((item) => item.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final initPoint = data['init_point'];

        if (await canLaunchUrl(Uri.parse(initPoint))) {
          await launchUrl(
            Uri.parse(initPoint),
            mode: LaunchMode
                .inAppWebView, // Cambiado de externalApplication a inAppWebView
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } else {
          throw Exception('No se pudo abrir el navegador');
        }
      } else {
        throw Exception('Error al crear la preferencia: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
