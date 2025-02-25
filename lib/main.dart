import 'dart:async';
import 'dart:convert';
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
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchDetailsScreen.dart';
import 'package:user_auth_crudd10/pages/screens/BonoScreen.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
import 'package:user_auth_crudd10/services/BonoService.dart';
 import 'package:user_auth_crudd10/services/functions/firebase_notification.dart';
import 'package:user_auth_crudd10/services/notifcationService.dart';
import 'package:user_auth_crudd10/services/providers/storage_ans_provider.dart';
import 'package:user_auth_crudd10/services/providers/storage_provider.dart';
import 'package:user_auth_crudd10/services/settings/theme_data.dart';
import 'package:user_auth_crudd10/services/settings/theme_provider.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

// Llaves globales
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
  final BonoService _bonoService = BonoService(baseUrl: baseUrl);

// Stream controller para estado del pago
final paymentStatusController = StreamController<Map<String, dynamic>>.broadcast();
final PaymentService _paymentService = PaymentService();

enum PaymentStatus { success, failure, approved, pending, unknown }

// Configuración de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_notification_channel',
    'Default Channel',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int isviewed = prefs.getInt('onBoard') ?? 1;

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

  await _setupDeepLinks();

runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Builder(
        builder: (context) {
          // Configurar navigatorKey después de que MaterialApp se inicialice
if (navigatorKey.currentState != null) {
  navigatorKey.currentState!.push(
    MaterialPageRoute(builder: (context) => BonosScreen(bonoService: _bonoService)),
  );
}          return MyApp(isviewed: isviewed);
        },
      ),
    ),
  );
}

Future<void> _setupDeepLinks() async {
  final appLinks = AppLinks();

  // Manejar deep link inicial solo si la app no está inicializando desde un estado autenticado
  try {
    final initialUri = await appLinks.getInitialAppLink();
    if (initialUri != null) {
      debugPrint('Deep link inicial: $initialUri');
      // Solo procesar si estamos en una pantalla que puede manejar pagos (por ejemplo, después de AuthCheckMain)
      if (navigatorKey.currentState != null) {
        _handleDeepLink(initialUri);
      }
    }
  } catch (e) {
    debugPrint('Error al obtener deep link inicial: $e');
  }

  // Manejar deep links en tiempo real
  appLinks.uriLinkStream.listen(
    (Uri? uri) {
      if (uri != null) {
        debugPrint('Deep link recibido: $uri');
        _handleDeepLink(uri);
      }
    },
    onError: (err) {
      debugPrint('Error al manejar deep link: $err');
    },
  );
}

void _handleDeepLink(Uri uri) async {
  debugPrint('Procesando deep link: ${uri.toString()}');
  debugPrint('Ruta del deep link: ${uri.path}');
  debugPrint('Parámetros del deep link: ${uri.queryParameters}');

  if (uri.scheme == 'footconnect' && uri.host == 'checkout') {
    String? paymentId = uri.queryParameters['payment_id'];
    String? externalReference = uri.queryParameters['external_reference'];
    Map<String, dynamic> event = {
      'paymentId': paymentId,
      'orderId': externalReference,
    };

    if (uri.path.contains('/success') || uri.path.contains('/approved')) {
      event['status'] = PaymentStatus.success;
      _onPaymentSuccess(uri); // Procesar éxito según el tipo
    } else if (uri.path.contains('/failure') || uri.path.contains('/rejected')) {
      event['status'] = PaymentStatus.failure;
    } else if (uri.path.contains('/pending') || uri.path.contains('/in_process')) {
      event['status'] = PaymentStatus.pending;
    } else {
      try {
        final paymentStatus = await _paymentService.verifyPaymentStatus(paymentId!);
        event['status'] = paymentStatus == 'approved' ? PaymentStatus.success : PaymentStatus.unknown;
        if (event['status'] == PaymentStatus.success) {
          _onPaymentSuccess(uri);
        }
      } catch (e) {
        debugPrint('Error al verificar el estado del pago: $e');
        event['status'] = PaymentStatus.unknown;
      }
    }
    paymentStatusController.add(event);
    return;
  }

  if (uri.scheme == 'miapp' && uri.host == 'partido') {
    final matchId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    if (matchId != null) {
      try {
        final match = await MatchService().getMatchById(matchId);
        if (match != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => MatchDetailsScreen(match: match),
            ),
          );
        } else {
          _showPaymentMessage('Partido no encontrado', Colors.red);
        }
      } catch (e) {
        debugPrint('Error al obtener partido: $e');
        _showPaymentMessage('Error al cargar el partido', Colors.red);
      }
    }
  }
}
void _onPaymentSuccess(Uri uri) async {
  final paymentId = uri.queryParameters['payment_id'];
  final externalReference = uri.queryParameters['external_reference'];

  try {
    final paymentStatus = await _paymentService.verifyPaymentStatus(paymentId!);
    if (paymentStatus == 'approved' || paymentStatus == 'success') {
      final orderResponse = await http.get(
        Uri.parse('https://proyect.aftconta.mx/api/orders/$externalReference'),
        headers: {
          'Authorization': 'Bearer ${await _paymentService.storage.getToken()}',
          'Accept': 'application/json',
        },
      );

      if (orderResponse.statusCode == 200) {
        final orderData = jsonDecode(orderResponse.body);
        debugPrint('Order data recibido: $orderData');
        debugPrint('Type de orderData[\'type\']: ${orderData['type'].runtimeType}');

        final orderType = orderData['type'].toString();

        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('¡Pago aprobado!')),
        );

        if (orderType == 'booking') {
          Navigator.of(navigatorKey.currentContext!).push(
            MaterialPageRoute(builder: (context) => const BookingScreen()),
          );
        } else if (orderType == 'bono') {
          Navigator.of(navigatorKey.currentContext!).push(
            MaterialPageRoute(builder: (context) => BonosScreen(bonoService: _bonoService)),
          );
        } else {
          debugPrint('Tipo de orden desconocido: $orderType');
          Navigator.of(navigatorKey.currentContext!).pop();
        }
      } else {
        debugPrint('Error al obtener la orden: ${orderResponse.body}');
        _showPaymentMessage('Error al procesar el pago', Colors.red);
      }
    } else {
      debugPrint('Estado de pago no esperado: $paymentStatus');
      _showPaymentMessage('Pago no aprobado', Colors.orange);
    }
  } catch (e) {
    debugPrint('Error al verificar el estado del pago: $e');
    _showPaymentMessage('Error al procesar el pago: $e', Colors.red);
  }
}

void _showPaymentMessage(String message, Color color) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _refreshBookings() {
  // Implementar si es necesario
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