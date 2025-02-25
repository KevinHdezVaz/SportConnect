import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/pages/others/profile_page.dart';
import 'package:user_auth_crudd10/pages/screens/BonoScreen.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
import 'package:user_auth_crudd10/pages/screens/fields_screen.dart';
import 'package:user_auth_crudd10/services/BonoService.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  final BonoService _bonoService = BonoService(baseUrl: baseUrl);
  late final List<Widget> _pages;
   void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

@override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      BonosScreen(bonoService: _bonoService),
      FieldsScreen(),
      ProfilePage(),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,  
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), 
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,  
              unselectedItemColor: Colors.white
                  .withOpacity(0.6),  
              backgroundColor:
                  Colors.blue, 
              currentIndex: _selectedIndex,
              onTap: _changeIndex,
              elevation: 0, 
              iconSize: 22,  
              selectedFontSize:
                  12, 
              unselectedFontSize:
                  12,  
              showSelectedLabels: true,  
              showUnselectedLabels: true,  
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
                      Icons.shopping_cart_sharp,
                      color: _selectedIndex == 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22, // Tamaño reducido del ícono
                    ),
                  ),
                  label: "Bonos",
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
