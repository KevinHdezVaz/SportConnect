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


      // Configurar canal de notificación
      // Esta es la parte importante para crear el canal
      await OneSignal.Notifications.removeNotification(0);
      await OneSignal.Notifications.requestPermission(true);
      
      // Configurar permisos
      OneSignal.Notifications.addPermissionObserver((state) {
        print("Has permission for push notifications: $state");
      });

      // Configurar nivel de debug
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Manejar notificaciones en primer plano
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('Notificación recibida en primer plano: ${event.notification.title}');
        // No prevenimos la notificación para que se muestre
      });

      // Manejar clics en notificaciones
      OneSignal.Notifications.addClickListener(_handleNotificationClick);

      // Esperar inicialización
      await Future.delayed(Duration(seconds: 2));
      
      await saveDeviceToken();
      
      OneSignal.User.pushSubscription.addObserver((state) {
        print('Observer - Cambio en pushSubscription: ${state.current.id}');
        if (state.current.id != null) {
          saveDeviceToken();
        }
      });
    }  catch (e) {
      print('Error en init de NotificationService: $e');
    }
  }

  static void _handleNotificationClick(OSNotificationClickEvent event) {
    print('Notificación clickeada: ${event.notification.title}');
    // Aquí puedes agregar lógica para navegar a una pantalla específica
  }

 static Future<void> saveDeviceToken() async {
  try {
    final playerId = OneSignal.User.pushSubscription.id;
    final userId = await AuthService().getCurrentUserId();
    
    print('Intentando guardar token:');
    print('Player ID: $playerId');
    print('User ID: $userId');

    if (playerId != null && userId != null) {
      final token = await StorageService().getToken();
      
      final response = await http.post(
        Uri.parse('https://proyect.aftconta.mx/api/store-player-id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'player_id': playerId,
          'user_id': userId.toString(),
        }),
      );

      print('Respuesta del servidor:');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al guardar token: ${response.body}');
      }
    } else {
      print('Error: valores nulos');
      print('Player ID: $playerId');
      print('User ID: $userId');
    }
  } catch (e, stackTrace) {
    print('Error en saveDeviceToken: $e');
    print('Stack trace: $stackTrace');
  }
}

  static Future<void> setupNotifications() async {
    await init();
  }
}