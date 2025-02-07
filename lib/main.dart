// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int isviewed = prefs.getInt('onBoard') ?? 1;

  await NotificationService.init();
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

GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  final int isviewed;

  const MyApp({super.key, required this.isviewed});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => StorageProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => StorageAnsProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.currentTheme,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: isviewed != 0 ? OnboardingWrapper() : AuthCheckMain(),
      ),
    );
  }
}
