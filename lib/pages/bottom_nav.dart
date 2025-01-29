import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/pages/others/profile_page.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
import 'package:user_auth_crudd10/pages/screens/fields_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _pages = [
    HomePage(),
    BookingScreen(),
    FieldsScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.blue, // Fondo azul para el BottomNavigationBar
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), // Bordes redondeados
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white, // Color del ítem seleccionado
              unselectedItemColor: Colors.white
                  .withOpacity(0.6), // Color del ítem no seleccionado
              backgroundColor:
                  Colors.blue, // Fondo azul para el BottomNavigationBar
              currentIndex: _selectedIndex,
              onTap: _changeIndex,
              elevation: 0, // Eliminar la sombra
              iconSize: 22, // Tamaño más pequeño para los íconos
              selectedFontSize:
                  12, // Tamaño de fuente más pequeño para el texto seleccionado
              unselectedFontSize:
                  12, // Tamaño de fuente más pequeño para el texto no seleccionado
              showSelectedLabels: true, // Mostrar etiquetas seleccionadas
              showUnselectedLabels: true, // Mostrar etiquetas no seleccionadas
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(6), // Padding reducido
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 0
                          ? Colors.white.withOpacity(
                              0.2) // Círculo blanco alrededor del ítem seleccionado
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.home,
                      color: _selectedIndex == 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22, // Tamaño reducido del ícono
                    ),
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(6), // Padding reducido
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 1
                          ? Colors.white.withOpacity(
                              0.2) // Círculo blanco alrededor del ítem seleccionado
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.question_answer,
                      color: _selectedIndex == 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22, // Tamaño reducido del ícono
                    ),
                  ),
                  label: "Reservas",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(6), // Padding reducido
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 2
                          ? Colors.white.withOpacity(
                              0.2) // Círculo blanco alrededor del ítem seleccionado
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _selectedIndex == 2
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22, // Tamaño reducido del ícono
                    ),
                  ),
                  label: "Canchas",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(6), // Padding reducido
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 3
                          ? Colors.white.withOpacity(
                              0.2) // Círculo blanco alrededor del ítem seleccionado
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.person,
                      color: _selectedIndex == 3
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22, // Tamaño reducido del ícono
                    ),
                  ),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
