// lib/services/payment_service.dart
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
      print('token laravel $token');

      // Combinar los items con los datos adicionales
      final Map<String, dynamic> requestBody = {
        'items': items.map((item) => item.toJson()).toList(),
        ...additionalData, // Agregar los datos adicionales
      };

      final response = await http.post(
        Uri.parse('$baseUrl/payments/create-preference'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );

      print('Response from backend: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final initPoint = data['init_point'];
        await _launchUrl(context, initPoint);
      } else {
        throw Exception('Error al crear la preferencia: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión o procesamiento: $e');
    }
  }
}