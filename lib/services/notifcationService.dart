import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'dart:convert';

import 'package:user_auth_crudd10/services/storage_service.dart';

class NotificationService {

 

  static Future<void> init() async {
    try {
      // Inicializar OneSignal
      OneSignal.initialize('90fd23c4-a605-40ed-ab39-78405c75a705');

      // Configurar para manejar notificaciones en segundo plano
      OneSignal.Notifications.addClickListener(_handleNotificationClick);

      // Configurar para manejar notificaciones cuando la app está cerrada
      OneSignal.Notifications.addPermissionObserver((state) {
        print("Has permission for push notifications: $state");
      });

      // Solicitar permisos de notificación
      await OneSignal.Notifications.requestPermission(true);

      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Esperar un momento para que OneSignal se inicialice completamente
      await Future.delayed(Duration(seconds: 2));

      // Intentar obtener y guardar el token
      await saveDeviceToken();

      // Agregar observer para cuando el token cambie
      OneSignal.User.pushSubscription.addObserver((state) {
        print('Observer - Cambio en pushSubscription: ${state.current.id}');
        if (state.current.id != null) {
          saveDeviceToken();
        }
      });

      // Manejar notificación cuando la app está en primer plano
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print(
            'Notificación recibida en primer plano: ${event.notification.title}');
        // Puedes agregar lógica para mostrar la notificación
      });
    } catch (e) {
      print('Error en init de NotificationService: $e');
    }
  }

  // Método para manejar clics en notificaciones
  static void _handleNotificationClick(OSNotificationClickEvent event) {
    print('Notificación clickeada: ${event.notification.title}');
    // Aquí puedes agregar lógica para navegar a una pantalla específica
    // Por ejemplo:
    // Navigator.pushNamed(context, '/notification-detail');
  }

static Future<void> saveDeviceToken() async {
  try {
    final playerId = OneSignal.User.pushSubscription.id;
    print('Intentando obtener Player ID: $playerId');
    
    final userId = await AuthService().getCurrentUserId();
    print('User ID obtenido: $userId'); // Log para verificar el userId

    if (playerId != null && userId != null) {
      final token = await StorageService().getToken();
      print('Token obtenido: $token'); // Log para verificar el token

      final response = await http.post(
        Uri.parse('https://proyect.aftconta.mx/api/store-player-id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'player_id': playerId,
          'user_id': userId,
        }),
      );

      print('Request enviado:');
      print('Headers: ${jsonEncode({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })}');
      print('Body: ${jsonEncode({
        'player_id': playerId,
        'user_id': userId,
      })}');
      
      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');
    } else {
      print('Error: playerId o userId es null');
      print('playerId: $playerId');
      print('userId: $userId');
    }
  } catch (e, stackTrace) {
    print('Error en saveDeviceToken: $e');
    print('Stack trace: $stackTrace');
  }
}
  // Método para configurar las notificaciones al iniciar la app
  static Future<void> setupNotifications() async {
    await init();
  }
}
