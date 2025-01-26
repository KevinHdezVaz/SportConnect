import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/pages/CanchasMap.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/pages/others/answer_page.dart';
import 'package:user_auth_crudd10/pages/others/profile_page.dart';
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
        : Theme.of(context).colorScheme.secondary;
  }

  List<Widget> _pages = [
    HomePage(),
    AnswerPage(),
    FieldsScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: BottomNavigationBar(
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Colors.grey[500],
          // backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: _changeIndex,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home, // Usamos el ícono de casa
                color: _iconColor(0),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.question_answer,
                color: _iconColor(1),
                size: 25,
              ),
              label: "Answers",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons
                    .location_on, // Usamos el ícono de cancha (puedes cambiarlo)
                color: _iconColor(2),
                size: 25, // Ajusta el tamaño del ícono
              ),
              label: "Canchas",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person, // Usamos el ícono de perfil
                color: _iconColor(3),
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
