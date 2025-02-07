import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/detalle_equipo.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/invitaciones.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/lista_equipos_screen.dart';
import 'package:user_auth_crudd10/pages/userProfileEdit_page.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

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
      setState(() {
        _invitacionesPendientes = count;
      });
    } catch (e) {
      print('Error cargando invitaciones: $e');
    }
  }

  Future<void> navegarEquipos(BuildContext context) async {
    setState(() => _isLoadingEquipos = true);

    try {
      if (userData == null || userData!['id'] == null) {
        throw Exception('No hay datos del usuario');
      }

      final userId = userData!['id'];
      final equipos = await _equipoService.getEquipos();

      // Buscar el equipo donde el usuario es miembro
      final miEquipo = equipos
          .where((e) => e.miembros.any((m) => m.id == userId))
          .firstOrNull; // Usamos firstOrNull en lugar de firstWhere

      if (miEquipo != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleEquipoScreen(
              equipo: miEquipo,
              userId: userId,
            ),
          ),
        );
      } else {
        // Si no tiene equipo, ir a lista de equipos
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListaEquiposScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar equipos: $e')),
      );
    } finally {
      setState(() => _isLoadingEquipos = false);
    }
  }



void _mostrarCodigo() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Mi Código para unirme a equipos.', style: TextStyle(color: Colors.black),),
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
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: userData!['invite_code'] ?? '',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Código copiado!',)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar', style: TextStyle(color: Colors.black),),
        ),
      ],
    ),
  );
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 127, 205, 234),
                              Color.fromARGB(255, 104, 151, 193)
                            ],
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
                             
                            
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    tabs: [
                      Tab(
                        child: Text(
                          'OPCIONES',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'ESTADÍSTICAS',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    indicatorColor: Colors.green,
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab de Opciones
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildMenuItem(
                                  icon: Icons.person,
                                  title: 'Editar Perfil',
                                  subtitle: 'Datos de usuario',
                                  onTap: () {},
                                ),
                                _buildMenuItem(
                                  icon: Icons.notifications,
                                  title: 'Invitaciones',
                                  subtitle: 'Ver invitaciones',
                                  count: _invitacionesPendientes,
                                  onTap: () => invitaciones(),
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

                        // Tab de Estadísticas
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Información',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatCard('29', 'Partidos'),
                                    _buildStatCard('1', 'Seguidores'),
                                    _buildStatCard('2', 'MVP'),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'Evaluación',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildEvaluationRow('Nivel', 5, 5),
                                _buildEvaluationRow('Actitud', 4, 5),
                                _buildEvaluationRow('Part.', 0, 5),
                                _buildEvaluationRow('Nº. MVP', 37, 100,
                                    isCount: true),
                                _buildEvaluationRow('Usuarios', 10, 100,
                                    isCount: true),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void invitaciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvitacionesScreen(),
      ),
    );
  }
}

Widget _buildStatCard(String value, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}
 

Widget _buildEvaluationRow(String label, int value, int maxValue,
    {bool isCount = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / maxValue,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          isCount ? value.toString() : '$value/$maxValue',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMenuItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  int count = 0, // Inicializado con 0 por defecto
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
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
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    
                    count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    title: Text(
      title,
      style: GoogleFonts.inter(
        color: Colors.blue,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.grey,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: Colors.green,
    ),
    onTap: onTap,
  );
}

Widget _buildNotificationItem() {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(Icons.notifications_outlined, color: Colors.black),
    ),
    title: Text(
      'Notificaciones',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: Text(
      'Activado',
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.grey,
      ),
    ),
    trailing: Switch(
      value: true,
      onChanged: (value) {},
      activeColor: Colors.green,
    ),
  );
}

class ProfilePic extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const ProfilePic({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (userData != null && userData!['profile_image'] != null) {
      imageUrl =
          'https://proyect.aftconta.mx/storage/${userData!['profile_image']}';
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
                  : const AssetImage('assets/icons/jugadore.png')
                      as ImageProvider,
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
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    backgroundColor: const Color.fromARGB(255, 100, 148, 220),
                  ),
                  onPressed: () {},
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
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
  }) : super(key: key);

  final String text;
  final IconData icon;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Card(
        elevation: 10,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromARGB(255, 39, 164, 199),
            padding: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: press,
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.blueGrey,
                size: 22,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
