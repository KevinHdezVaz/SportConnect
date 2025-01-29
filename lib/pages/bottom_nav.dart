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

  Color _iconColor(int index) {
    return _selectedIndex == index
        ? Theme.of(context).colorScheme.primary
        : const Color.fromARGB(255, 109, 103, 103);
  }

  List<Widget> _pages = [
    HomePage(),
    BookingScreen(),
    FieldsScreen(),
    ProfilePage( toggleDarkMode: toggleDarkMode,
                  isDarkMode: isDarkMode,),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: BottomNavigationBar(
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Colors.black, // Para un alto contraste.
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: _changeIndex,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8), // Ajusta el padding según sea necesario
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados
                ),
                child: Icon(
                  Icons.home,
                  color: _iconColor(0),
                ),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.question_answer,
                  color: _iconColor(1),
                  size: 25,
                ),
              ),
              label: "Reservas",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: _iconColor(2),
                  size: 25,
                ),
              ),
              label: "Canchas",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 3
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: _iconColor(3),
                ),
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}