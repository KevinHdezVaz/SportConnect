import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/others/StatsTab.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/detalle_equipo.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/invitaciones.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/lista_equipos_screen.dart';
import 'package:user_auth_crudd10/pages/screens/UpdateProfileScreen.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
 
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  Map<String, dynamic>? userData;
  final _equipoService = EquipoService();
  bool _isLoadingEquipos = false;
  int _invitacionesPendientes = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadInvitaciones();
  }

  Future<void> _loadInvitaciones() async {
    try {
      final count = await _equipoService.getInvitacionesPendientesCount();
      setState(() => _invitacionesPendientes = count);
    } catch (e) {
      print('Error cargando invitaciones: $e');
    }
  }

  Future<void> navegarEquipos(BuildContext context) async {
    setState(() => _isLoadingEquipos = true);
    try {
      if (userData == null || userData!['id'] == null) throw Exception('No hay datos del usuario');
      final userId = userData!['id'];
      final equipos = await _equipoService.getEquipos();
      final miEquipo = equipos.where((e) => e.miembros.any((m) => m.id == userId)).firstOrNull;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => miEquipo != null
              ? DetalleEquipoScreen(equipo: miEquipo, userId: userId)
              : ListaEquiposScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar equipos: $e')));
    } finally {
      setState(() => _isLoadingEquipos = false);
    }
  }

  void _mostrarCodigo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mi Código para unirme a equipos', style: TextStyle(color: Colors.black)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code, size: 50, color: Colors.blue),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userData!['invite_code'] ?? '',
                      style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: userData!['invite_code'] ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Código copiado!')));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar', style: TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _authService.getProfile();
      setState(() => userData = response);
    } catch (e) {
      print('Error cargando perfil: $e');
    }
  }

  Future<void> _logout() async {
    try {
      showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
      await _authService.logout();
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => AuthCheckMain()), (route) => false);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      print('Error cerrando sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  ProfilePic(userData: userData),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 127, 205, 234), Color.fromARGB(255, 104, 151, 193)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blueGrey, size: 24),
                                  const SizedBox(width: 20),
                                  Text(
                                    userData!['name'] ?? '',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.blueGrey, size: 24),
                                  const SizedBox(width: 20),
                                  Text(
                                    userData!['email'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    tabs: [
                      Tab(child: Text('OPCIONES', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))),
                      Tab(child: Text('ESTADÍSTICAS', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))),
                    ],
                    indicatorColor: Colors.green,
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildMenuItem(
                                  icon: Icons.person,
                                  title: 'Editar Perfil',
                                  subtitle: 'Datos de usuario',
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateProfileScreen())),
                                ),
                                _buildMenuItem(
                                  icon: Icons.notifications,
                                  title: 'Invitaciones',
                                  subtitle: 'Ver invitaciones',
                                  count: _invitacionesPendientes,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InvitacionesScreen())),
                                ),
                                _buildMenuItem(
                                  icon: Icons.qr_code,
                                  title: 'Mi Código',
                                  subtitle: 'Para unirme a equipos',
                                  onTap: _mostrarCodigo,
                                ),
                            
                                _buildMenuItem(
                                  icon: Icons.group,
                                  title: 'Mi Equipo',
                                  subtitle: 'Ver equipo',
                                  onTap: () => navegarEquipos(context),
                                ),
                                _buildMenuItem(
                                  icon: Icons.exit_to_app,
                                  title: 'Cerrar sesión',
                                  subtitle: 'Salir',
                                  onTap: _logout,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const StatsTab(), // Usar la nueva clase StatsTab
                      ],
                    ),
                  ),
                ], 
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int count = 0,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.black),
            if (count > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(count.toString(), style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(title, style: GoogleFonts.inter(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.green),
      onTap: onTap,
    );
  }
}

// Mantén ProfilePic y otras clases aquí si no las mueves a otro archivo
class ProfilePic extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const ProfilePic({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? imageUrl = userData != null && userData!['profile_image'] != null
        ? 'https://proyect.aftconta.mx/storage/${userData!['profile_image']}'
        : null;
    return SafeArea(
      child: SizedBox(
        height: 115,
        width: 115,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : const AssetImage('assets/icons/jugadore.png') as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) => print('Error loading image: $exception'),
            ),
            Positioned(
              right: -16,
              bottom: 0,
              child: SizedBox(
                height: 46,
                width: 46,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    backgroundColor: const Color.fromARGB(255, 100, 148, 220),
                  ),
                  onPressed: () {},
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}