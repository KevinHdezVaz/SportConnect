 import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_notification_channel', // ID del canal
    'Default Channel', // Nombre del canal
    description: 'This channel is used for important notifications.', // Descripción
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  print('Canal de notificaciones creado: ${channel.id}'); // Mensaje de depuración
}