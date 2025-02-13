// ignore: depend_on_referenced_packages
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

// Agregar esta llave para la navegación global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int isviewed = prefs.getInt('onBoard') ?? 1;

  // Configurar deep links
  await _setupDeepLinks();

  // Otras inicializaciones
  try {
    await NotificationService.setupNotifications();
    print('NotificationService inicializado correctamente');
  } catch (e) {
    print('Error al inicializar NotificationService: $e');
  }

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirbaseApi().initNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(isviewed: isviewed),
    ),
  );
}

Future<void> _setupDeepLinks() async {
  final appLinks = AppLinks();

  // Manejar links iniciales (app cerrada)
  try {
    final initialUri = await appLinks.getInitialAppLink();
    if (initialUri != null) {
      debugPrint('Initial URI: $initialUri');
      _handlePaymentDeepLink(initialUri);
    }
  } catch (e) {
    debugPrint('Error getting initial uri: $e');
  }

  // Manejar links en primer plano
  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      debugPrint('Received deep link: $uri');
      _handlePaymentDeepLink(uri);
    }
  }, onError: (err) {
    debugPrint('Error handling deep link: $err');
  });
}

void _handlePaymentDeepLink(Uri uri) {
  // Extraer información del pago
  final paymentId = uri.queryParameters['payment_id'];
  final status = uri.queryParameters['status'];
  
  debugPrint('Payment ID: $paymentId, Status: $status');

  // Mostrar mensaje según el estado
  if (uri.path.contains('/payment/success')) {
    _showPaymentMessage('¡Pago exitoso! Tu reserva ha sido confirmada.', Colors.green);
    // Refrescar la pantalla de reservas
    _refreshBookings();
  } else if (uri.path.contains('/payment/failure')) {
    _showPaymentMessage('El pago no pudo completarse.', Colors.red);
  } else if (uri.path.contains('/payment/pending')) {
    _showPaymentMessage('El pago está pendiente de confirmación.', Colors.orange);
  }
}

void _showPaymentMessage(String message, Color color) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      duration: Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _refreshBookings() {
  // Aquí puedes implementar la lógica para refrescar la pantalla de reservas
  // Por ejemplo, usando un provider o un bloc
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
        navigatorKey: navigatorKey, // Agregar la llave de navegación
        scaffoldMessengerKey: scaffoldMessengerKey, // Agregar la llave del scaffold messenger
        themeMode: themeProvider.currentTheme,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: isviewed != 0 ? OnboardingWrapper() : AuthCheckMain(),
      ),
    );
  }
}