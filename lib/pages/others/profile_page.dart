import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/userProfileEdit_page.dart';

class ProfilePage extends StatefulWidget {
  final Function(bool) toggleDarkMode;
  final bool isDarkMode;

  const ProfilePage(
      {super.key, required this.toggleDarkMode, required this.isDarkMode});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _authService.getProfile();
      setState(() {
        userData = response;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
    }
  }

  Future<void> _logout() async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      await _authService.logout();

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthCheckMain()),
          (route) => false);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      print('Error cerrando sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('User Data: $userData');

    return Scaffold(
      backgroundColor: Colors.white,
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
ProfilePic(userData: userData, isDarkMode: widget.isDarkMode),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade100,
                                  const Color.fromARGB(255, 74, 145, 207)
                                ], // Degradado
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.blueGrey, size: 24),
                                      const SizedBox(width: 20),
                                      Text(
                                        userData!['name'] ?? '',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.email,
                                          color: Colors.blueGrey, size: 24),
                                      const SizedBox(width: 20),
                                      Text(
                                        userData!['email'] ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UserProfileEdit(),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit,
                                            color: Colors.blueGrey, size: 24),
                                        const SizedBox(width: 20),
                                        Text(
                                          "Editar",
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ProfileMenu(
                               isDarkMode: widget.isDarkMode,
                          text: "Notificaciones",
                          icon: Icons.notifications,
                          press: () {},
                        ),
                        
                        ProfileMenu(
                               isDarkMode: widget.isDarkMode,
                          text: "Ajustes",
                          icon: Icons.settings,
                          press: () {},
                        ),
                        const SizedBox(height: 20),
                        ProfileMenu(
isDarkMode: widget.isDarkMode,                          text: "Cerrar sesión",
                          icon: Icons.logout,
                          press: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const ProfilePic({
    Key? key,
    required this.userData,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (userData != null && userData!['profile_image'] != null) {
      imageUrl =
          'https://srv471-files.hstgr.io/45b73e2b7df2ce51/files/public_html/proyect/storage/app/public/${userData!['profile_image']}';
    }

    return SafeArea(
      child: SizedBox(
        height: 115,
        width: 115,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/icons/jugadore.png') as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading image: $exception');
                const AssetImage('assets/icons/jugadore.png');
              },
            ),
            Positioned(
              right: -16,
              bottom: 0,
              child: SizedBox(
                height: 46,
                width: 46,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: BorderSide(color: isDarkMode ? Colors.black : Colors.white),
                    ),
                    backgroundColor: isDarkMode ? Colors.grey[800] : const Color(0xFFF5F6F9),
                  ),
                  onPressed: () {},
                  child: Icon(
                    Icons.camera_alt,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    Key? key,
    required this.text,
    required this.icon,
    this.press,
    required this.isDarkMode,
  }) : super(key: key);

  final String text;
  final IconData icon;
  final VoidCallback? press;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Card(
        elevation: 10,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: isDarkMode ? Colors.white : const Color.fromARGB(255, 39, 164, 199),
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: isDarkMode ? Colors.grey[800] : const Color(0xFFF5F6F9),
          ),
          onPressed: press,
          child: Row(
            children: [
              Icon(
                icon,
                color: isDarkMode ? Colors.white : Colors.blueGrey,
                size: 22,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : const Color(0xFF757575),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDarkMode ? Colors.white : const Color(0xFF757575),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
