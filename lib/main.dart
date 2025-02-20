// ignore: depend_on_referenced_packages
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/onscreen/onboardingWrapper.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
import 'package:user_auth_crudd10/services/functions/firebase_notification.dart';
import 'package:user_auth_crudd10/services/notifcationService.dart';
import 'package:user_auth_crudd10/services/providers/storage_ans_provider.dart';
import 'package:user_auth_crudd10/services/providers/storage_provider.dart';
import 'package:user_auth_crudd10/services/settings/theme_data.dart';
import 'package:user_auth_crudd10/services/settings/theme_provider.dart';
import 'firebase_options.dart';

// Llaves globales
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Stream controller para estado del pago
final paymentStatusController = StreamController<PaymentStatus>.broadcast();
final PaymentService _paymentService = PaymentService();

enum PaymentStatus {
  success,
  failure,
  approved,
  pending,
  unknown
}

// Configuración de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_notification_channel', // ID del canal
    'Default Channel', // Nombre del canal
    description: 'This channel is used for important notifications.', // Descripción
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializaciones
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int isviewed = prefs.getInt('onBoard') ?? 1;

    // Crear el canal de notificación
  await createNotificationChannel();
  

  try {
    await NotificationService.setupNotifications();
    debugPrint('NotificationService inicializado correctamente');
  } catch (e) {
    debugPrint('Error al inicializar NotificationService: $e');
  }

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirbaseApi().initNotifications();

  // Configurar deep links
  await _setupDeepLinks();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(isviewed: isviewed),
    ),
  );
}

Future<void> _setupDeepLinks() async {
  final appLinks = AppLinks();

  // Manejar deep link inicial (app cerrada)
  try {
    final initialUri = await appLinks.getInitialAppLink();
    if (initialUri != null) {
      debugPrint('Deep link inicial: $initialUri');
      _handlePaymentDeepLink(initialUri);
    }
  } catch (e) {
    debugPrint('Error al obtener deep link inicial: $e');
  }

  // Manejar deep links en primer plano
  appLinks.uriLinkStream.listen(
    (Uri? uri) {
      if (uri != null) {
        debugPrint('Deep link recibido: $uri');
        _handlePaymentDeepLink(uri);
      }
    },
    onError: (err) {
      debugPrint('Error al manejar deep link: $err');
    },
  );
}

 void _handlePaymentDeepLink(Uri uri) async {
  debugPrint('Procesando deep link de pago: ${uri.toString()}');
  debugPrint('Ruta del deep link: ${uri.path}');
  debugPrint('Parámetros del deep link: ${uri.queryParameters}');

  PaymentStatus status;

  if (uri.path.contains('/checkout/success') || uri.path.contains('/checkout/approved')) {
    status = PaymentStatus.success;
  } else if (uri.path.contains('/checkout/failure') || uri.path.contains('/checkout/rejected')) {
    status = PaymentStatus.failure;
  } else if (uri.path.contains('/checkout/pending') || uri.path.contains('/checkout/in_process')) {
    status = PaymentStatus.pending;
  } else {
    // Estado desconocido: verificar con el backend
    final paymentId = uri.queryParameters['payment_id'];
    try {
      final paymentStatus = await _paymentService.verifyPaymentStatus(paymentId!);
      if (paymentStatus == 'approved' || paymentStatus == 'success') {
        status = PaymentStatus.success;
      } else {
        status = PaymentStatus.unknown;
      }
    } catch (e) {
      debugPrint('Error al verificar el estado del pago: $e');
      status = PaymentStatus.unknown;
    }
  }

  paymentStatusController.add(status);
}
void _onPaymentSuccess(Uri uri) async {
  final paymentId = uri.queryParameters['payment_id'];
  final externalReference = uri.queryParameters['external_reference'];

  try {
    final paymentStatus = await _paymentService.verifyPaymentStatus(paymentId!);
    if (paymentStatus == 'approved' || paymentStatus == 'success') {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('¡Pago aprobado!')),
      );
      Navigator.of(navigatorKey.currentContext!).pushReplacement(
        MaterialPageRoute(builder: (context) => const BookingScreen()),
      );
    } else {
      debugPrint('Estado de pago no esperado: $paymentStatus');
    }
  } catch (e) {
    debugPrint('Error al verificar el estado del pago: $e');
  }
}


void _showPaymentMessage(String message, Color color) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _refreshBookings() {
  // Implementar lógica para actualizar la lista de reservas
  // Por ejemplo:
  // Provider.of<BookingsProvider>(navigatorKey.currentContext!, listen: false).loadBookings();
}

class MyApp extends StatelessWidget {
  final int isviewed;
  
  const MyApp({super.key, required this.isviewed});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StorageProvider()),
        ChangeNotifierProvider(create: (context) => StorageAnsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        themeMode: themeProvider.currentTheme,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: isviewed != 0 ? OnboardingWrapper() : AuthCheckMain(),
      ),
    );
  }
}