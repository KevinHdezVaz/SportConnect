import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
 brightness: Brightness.light,
 colorScheme: const ColorScheme.light(
   surface: Colors.white,
   primary: Color(0xFF4CACFF),    // Celeste principal
   secondary: Color(0xFFA8D5FF),  // Celeste claro
   onPrimary: Color(0xFF1E90FF),  // Celeste oscuro
   onSecondary: Color(0xFFE8F4FF),// Gris muy claro
   onSurface: Color(0xFF66CCFF),  // Celeste brillante
   background: Color(0xFFF5F5F5), // Blanco hueso
 ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: Colors.black,
    primary: Color.fromARGB(255, 34, 34, 34),
    secondary: Color.fromARGB(255, 238, 238, 238),
  ),
);
