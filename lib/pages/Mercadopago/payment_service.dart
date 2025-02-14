import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  final storage = StorageService();

Future<void> _launchUrl(BuildContext context, String url) async {
    final theme = Theme.of(context);
    try {
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: theme.colorScheme.surface,
            navigationBarColor: theme.colorScheme.surface,
          ),
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: theme.colorScheme.surface,
          preferredControlTintColor: theme.colorScheme.onSurface,
          barCollapsingEnabled: true,
          entersReaderIfAvailable: false,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('No se pudo abrir el navegador: $e');
    }
}


  Future<void> procesarPago(
    BuildContext context,
    List<OrderItem> items,
    {required Map<String, dynamic> additionalData}
  ) async {
    try {
      final token = await storage.getToken();
      debugPrint('Token: $token');

      // Formatear los items
      final formattedItems = items.map((item) => {
        "title": item.title,
        "quantity": item.quantity,
        "currency_id": "MXN",
        "unit_price": item.unitPrice
      }).toList();

      // Crear el cuerpo de la solicitud
      final Map<String, dynamic> requestBody = {
        'items': formattedItems,
        'payer': {
          'name': additionalData['customer']['name'],
          'email': additionalData['customer']['email'],
        },
        'external_reference': additionalData['external_reference'] ?? 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
        'notification_url': 'https://proyect.aftconta.mx/api/webhook/mercadopago',
        'additionalData': {
          'field_id': additionalData['field_id'],
          'date': additionalData['date'],
          'start_time': additionalData['start_time'],
          'players_needed': additionalData['players_needed'],
        }
      };

      debugPrint('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/payments/create-preference'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final initPoint = data['init_point'];
        await _launchUrl(context, initPoint);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error al crear la preferencia: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      debugPrint('Error en procesarPago: $e');
      throw Exception('Error de conexión o procesamiento: $e');
    }
  }
}