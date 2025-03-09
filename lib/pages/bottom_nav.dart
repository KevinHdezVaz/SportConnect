import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/pages/others/TiendaScreen.dart';
import 'package:user_auth_crudd10/pages/others/profile_page.dart';
import 'package:user_auth_crudd10/pages/screens/BonoScreen.dart';
import 'package:user_auth_crudd10/pages/screens/fields_screen.dart';
import 'package:user_auth_crudd10/services/BonoService.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;
  final BonoService _bonoService = BonoService(baseUrl: baseUrl);
  final StorageService _storageService = StorageService();
  late final List<Widget> _pages;
  bool _showStore = true; // Bandera para mostrar/ocultar "Tienda"
  bool _isLoadingSettings = true;

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    fetchSettings();

    // Lista completa de páginas
    _pages = [
      HomePage(),
      BonosScreen(bonoService: _bonoService),
      FieldsScreen(),
      TiendaScreen(),
      ProfilePage(),
    ];
  }

  Future<void> fetchSettings() async {
    final token = await _storageService.getToken();

    try {
      final url = Uri.parse('$baseUrl/settings/show_store');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _showStore = data['show_store'] == 'true';
          _isLoadingSettings = false;
        });
      } else {
        throw Exception(
            'Error al cargar configuraciones: Código de estado ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingSettings = false;
        _showStore = true; // Valor por defecto si falla la solicitud
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar configuraciones: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filtrar las páginas según _showStore
    List<Widget> filteredPages = _pages;
    if (!_showStore) {
      filteredPages =
          _pages.where((page) => page.runtimeType != TiendaScreen).toList();
      // Ajustar el índice seleccionado si está fuera del rango
      if (_selectedIndex >= filteredPages.length) {
        _selectedIndex = 0;
      }
    }

    return Scaffold(
      body: filteredPages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              backgroundColor: Colors.blue,
              currentIndex: _selectedIndex,
              onTap: _changeIndex,
              elevation: 0,
              iconSize: 22,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 0
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.home,
                      color: _selectedIndex == 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                  label: "Eventos",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 1
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.shopping_cart_sharp,
                      color: _selectedIndex == 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                  label: "Bonos",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 2
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _selectedIndex == 2
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                  label: "Canchas",
                ),
                if (_showStore) // Mostrar "Tienda" solo si _showStore es true
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 3
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.shop,
                        color: _selectedIndex == 3
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        size: 22,
                      ),
                    ),
                    label: "Tienda",
                  ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == (_showStore ? 4 : 3)
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.person,
                      color: _selectedIndex == (_showStore ? 4 : 3)
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                  label: "Perfil",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
