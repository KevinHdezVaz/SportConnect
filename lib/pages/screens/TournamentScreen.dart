import 'package:flutter/material.dart';

// Pantalla completa de torneos (screens/tournaments_screen.dart)
class TournamentsScreen extends StatefulWidget {
  @override
  _TournamentsScreenState createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Torneos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Activos'),
            Tab(text: 'Próximos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTournamentList('active'),
          _buildTournamentList('upcoming'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de crear torneo
        },
        child: Icon(Icons.add),
        tooltip: 'Crear Torneo',
      ),
    );
  }

  Widget _buildTournamentList(String type) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Navegar al detalle del torneo
            },
            child: Column(
              children: [
                Stack(
                  children: [
                    Image.network(
                      'https://img.olympics.com/images/image/private/t_s_16_9_g_auto/t_s_w1460/f_auto/primary/ngdjbafv3twathukjbq2',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Copa Verano 2025',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fútbol 7 • Categoría Libre',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem(
                              Icons.calendar_today, 'Inicio: 15 Feb'),
                          _buildInfoItem(Icons.sports_soccer, '12 Equipos'),
                          _buildInfoItem(Icons.attach_money, 'Premio: \$5,000'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Ver Detalles'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Inscribir Equipo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
