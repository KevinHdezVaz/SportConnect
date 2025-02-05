import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/crear_equipo_screen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/lista_equipos_screen.dart';
import 'package:user_auth_crudd10/pages/userProfileEdit_page.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                color: Colors.blueGrey,
                                                size: 24),
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
                          ),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
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
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    // Tab de Opciones
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMenuItem(
                          icon: Icons.person,
                          title: 'Editar Perfil',
                          subtitle: 'Datos de usuario',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.exit_to_app,
                          title: 'Cerrar sesión',
                          subtitle: 'Salir',
                          onTap: _logout,
                        ),
                        _buildMenuItem(
                          icon: Icons.group,
                          title: 'Crear equipos',
                          subtitle: 'Salir',
                          onTap: () => canchas(context),
                        ),
                      ],
                    ),
                    // Tab de Estadísticas
                    ListView(
                      padding: const EdgeInsets.all(16),
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        _buildEvaluationRow('Nº. MVP', 37, 100, isCount: true),
                        _buildEvaluationRow('Usuarios', 10, 100, isCount: true),
                        const SizedBox(height: 32),
                        Text(
                          'Eventos',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Número de partidos jugados en los últimos 5 meses.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const titles = [
                                        'Sep',
                                        'Oct',
                                        'Nov',
                                        'Dic',
                                        'Ene'
                                      ];
                                      if (value.toInt() < 0 ||
                                          value.toInt() >= titles.length) {
                                        return const Text('');
                                      }
                                      return Text(
                                        titles[value.toInt()],
                                        style: GoogleFonts.inter(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 0.5,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toString(),
                                        style: GoogleFonts.inter(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 4,
                              minY: -1,
                              maxY: 1,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 0),
                                    FlSpot(1, 0),
                                    FlSpot(2, 0),
                                    FlSpot(3, 0),
                                    FlSpot(4, 0),
                                  ],
                                  isCurved: false,
                                  color: Colors.green,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

void canchas(BuildContext context) {
  Navigator.push(
    // cambiado de pushReplacement a push
    context,
    MaterialPageRoute(builder: (context) => ListaEquiposScreen()),
  );
}

Widget _buildMenuItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
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
      child: Icon(icon, color: Colors.black),
    ),
    title: Text(
      title,
      style: GoogleFonts.inter(
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
