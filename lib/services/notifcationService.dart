import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';

class NotificationService {
  static Future<void> init() async {
      OneSignal.initialize('90fd23c4-a605-40ed-ab39-78405c75a705');
    await OneSignal.Notifications.requestPermission(true);

    // Manejar notificación cuando la app está en primer plano
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Lógica para mostrar la notificación en la app
    });
  }

  static Future<void> saveDeviceToken() async {
    final token = await OneSignal.User.pushSubscription.id;
    if (token != null) {
      await AuthService().updateDeviceToken(token);
    }
  }
}
