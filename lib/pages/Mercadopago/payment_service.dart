import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';

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

  Future<String> verifyPaymentStatus(String paymentId) async {
    try {
      final token = await storage.getToken();
      debugPrint('Token: $token');

      final url = Uri.parse('$baseUrl/payments/verify-status/$paymentId');
      debugPrint('URL de verificación: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentStatus = data['status'];
        debugPrint('Estado del pago: $paymentStatus');
        return paymentStatus;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error al verificar el estado del pago: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      debugPrint('Error en verifyPaymentStatus: $e');
      throw Exception('Error de conexión o procesamiento: $e');
    }
  }

 Future<Map<String, dynamic>> procesarPago(
  BuildContext context,
  List<OrderItem> items, {
  required Map<String, dynamic> additionalData,
  required String type,
}) async {
  try {
    final token = await storage.getToken();
    final formattedItems = items.map((item) => {
      "title": item.title,
      "quantity": item.quantity,
      "currency_id": "MXN",
      "unit_price": item.unitPrice
    }).toList();

    final requestBody = {
      'items': formattedItems,
      'type': type.toString(),
      'reference_id': additionalData['reference_id'],
      'additionalData': additionalData,
      'payer': {
        'name': additionalData['customer']['name'],
        'email': additionalData['customer']['email'],
      },
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _launchUrl(context, data['init_point']);

      final completer = Completer<Map<String, dynamic>>();
      StreamSubscription? subscription;

      subscription = paymentStatusController.stream.listen((event) async {
        subscription?.cancel();
        final paymentId = event['paymentId'] ?? await verifyPaymentStatus(data['order_id'].toString());
        completer.complete({
          'status': event['status'],
          'paymentId': paymentId,
          'orderId': data['order_id'].toString(), // Convertimos a String aquí
        });
      });

      return completer.future;
    } else {
      throw Exception('Error al crear la preferencia: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de conexión o procesamiento: $e');
  }
}
}