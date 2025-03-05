import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentDetails.dart';
import 'package:user_auth_crudd10/services/torneo_service.dart';

class TournamentsScreen extends StatefulWidget {
  @override
  _TournamentsScreenState createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  final TorneoService _torneoService = TorneoService();
  late Future<List<Torneo>> _torneosFuture;

  @override
  void initState() {
    super.initState();
 //   _torneosFuture = _torneoService.getTorneos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Torneos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navegar a pantalla de crear torneo
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Torneo>>(
        future: _torneosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error al cargar los torneos'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                     //   _torneosFuture = _torneoService.getTorneos();
                      });
                    },
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay torneos disponibles'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
          //      _torneosFuture = _torneoService.getTorneos();
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final torneo = snapshot.data![index];
                  return TorneoCard(torneo: torneo);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class TorneoCard extends StatelessWidget {
  final Torneo torneo;
  const TorneoCard({
    Key? key,
    required this.torneo,
  }) : super(key: key);

  Color getStatusColor() {
    switch (torneo.estado) {
      case 'en_progreso':
        return Colors.green;
      case 'abierto':
        return Colors.blue;
      case 'completado':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (torneo.imagenesTorneo != null &&
              torneo.imagenesTorneo!.isNotEmpty)
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
              ),
              items: torneo.imagenesTorneo!.map((imagen) {
                print('Intentando cargar imagen: $imagen');
                return Builder(
                  builder: (BuildContext context) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imagen,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            print('Estado de carga: $loadingProgress');
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error cargando imagen: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline),
                                  SizedBox(height: 8),
                                  Text(
                                    'Error al cargar imagen',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }).toList(),
            ),

          // Información del torneo
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            torneo.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            torneo.descripcion,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        torneo.estado,
                        style: TextStyle(
                          color: getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                InfoRow(
                  icons: [
                    Icons.calendar_today,
                    Icons.emoji_events,
                    Icons.group,
                    Icons.attach_money,
                  ],
                  texts: [
                    '${DateFormat('dd/MM/yyyy').format(torneo.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(torneo.fechaFin)}',
                    torneo.formato,
                    '${torneo.minimoEquipos}/${torneo.maximoEquipos} equipos',
                    '\$${torneo.cuotaInscripcion}',
                  ],
                ),
                if (torneo.premio != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        torneo.premio!,
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TournamentDetails(torneo: torneo),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver detalles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final List<IconData> icons;
  final List<String> texts;

  const InfoRow({
    Key? key,
    required this.icons,
    required this.texts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: List.generate(
        icons.length,
        (index) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons[index],
              size: 16,
              color: Colors.grey[600],
            ),
            SizedBox(width: 4),
            Text(
              texts[index],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
