// ignore: depend_on_referenced_packages
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/onscreen/onboardingWrapper.dart';
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

enum PaymentStatus {
  success,
  failure,
  pending,
  unknown
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializaciones
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int isviewed = prefs.getInt('onBoard') ?? 1;

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

void _handlePaymentDeepLink(Uri uri) {
  debugPrint('Procesando deep link de pago: ${uri.toString()}');
  
  PaymentStatus status;
  String message;
  Color color;

  // Extraer ID de pago y referencia externa si están presentes
  final paymentId = uri.queryParameters['payment_id'];
  final externalReference = uri.queryParameters['external_reference'];

  // Determinar estado basado en la ruta
  if (uri.path.contains('/checkout/success')) {
    status = PaymentStatus.success;
    message = '¡Pago exitoso! Tu reserva ha sido confirmada';
    color = Colors.green;
    _onPaymentSuccess(uri);
  } else if (uri.path.contains('/checkout/failure')) {
    status = PaymentStatus.failure;
    message = 'El pago no pudo completarse';
    color = Colors.red;
  } else if (uri.path.contains('/checkout/pending')) {
    status = PaymentStatus.pending;
    message = 'El pago está pendiente de confirmación';
    color = Colors.orange;
  } else {
    status = PaymentStatus.unknown;
    message = 'Estado de pago desconocido';
    color = Colors.grey;
  }

  // Notificar a través del stream
  paymentStatusController.add(status);

  // Mostrar mensaje al usuario
  _showPaymentMessage(message, color);

  debugPrint('Detalles del pago:');
  debugPrint('ID de pago: $paymentId');
  debugPrint('Referencia externa: $externalReference');
}

void _onPaymentSuccess(Uri uri) {
  final paymentId = uri.queryParameters['payment_id'];
  final externalReference = uri.queryParameters['external_reference'];

  // Aquí puedes implementar llamadas a tu API o actualizar el estado local
  _refreshBookings();
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