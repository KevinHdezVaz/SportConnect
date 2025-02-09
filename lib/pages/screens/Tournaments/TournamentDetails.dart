import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/SeleccionarEquipoScreen.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
import 'package:user_auth_crudd10/services/torneo_service.dart';

class TournamentDetails extends StatefulWidget {
  final Torneo torneo;

  const TournamentDetails({Key? key, required this.torneo}) : super(key: key);

  @override
  State<TournamentDetails> createState() => _TournamentDetailsState();
}

class _TournamentDetailsState extends State<TournamentDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TorneoService _torneoService = TorneoService();
  Map<String, dynamic>? _torneoDetails;
  bool _isLoading = true;
  Map<String, dynamic>? userData;

  final _equipoService = EquipoService();
  bool _inscribiendose = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTorneoDetails();
  }

  Future<void> _loadTorneoDetails() async {
    try {
      print(
          'Obteniendo detalles del torneo: https://proyect.aftconta.mx/api/torneos/${widget.torneo.id}');

      final details = await _torneoService.getTorneoDetails(widget.torneo.id);

      if (mounted) {
        setState(() {
          _torneoDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando detalles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los detalles del torneo'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _loadTorneoDetails(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildHeaderImage(),
                      title: Text(
                        widget.torneo.nombre,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Material(
                child: Container(
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      _buildQuickInfo(),
                      TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                        tabs: [
                          Tab(
                            icon: Icon(Icons.info_outline),
                            text: 'Información',
                          ),
                          Tab(
                            icon: Icon(Icons.table_chart),
                            text: 'Tabla',
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInfoTab(),
                            _buildStandingsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: widget.torneo.estado == 'abierto'
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navegar a la pantalla SeleccionarEquipoScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeleccionarEquipoScreen(
                      torneoId: widget.torneo.id, // Pasar el ID del torneo
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.sports_soccer,
                color: Colors.white,
              ),
              label: Text(
                'Unirme al Torneo',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.lightBlue,
            )
          : null,
    );
  }

// Agrega estos métodos:
  void _mostrarDialogoInscripcion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inscripción al Torneo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas inscribir tu equipo a este torneo?'),
            SizedBox(height: 16),
            if (widget.torneo.cuotaInscripcion > 0)
              Text(
                'Cuota de inscripción: \$${widget.torneo.cuotaInscripcion}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              //   _inscribirEquipo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<File?> _seleccionarComprobante() async {
    return await showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comprobante de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Por favor, sube una foto del comprobante de pago'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Seleccionar Foto'),
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1000,
                  maxHeight: 1000,
                );
                Navigator.pop(context, image != null ? File(image.path) : null);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    if (widget.torneo.imagenesTorneo == null ||
        widget.torneo.imagenesTorneo!.isEmpty) {
      return Container(
        color: Theme.of(context).primaryColor,
        child: Center(
          child: Icon(Icons.sports_soccer, size: 80, color: Colors.white),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 5),
      ),
      items: widget.torneo.imagenesTorneo!.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.8),
                      child: Icon(Icons.error_outline, color: Colors.white),
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
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickInfo() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(),
            SizedBox(height: 16),
            Text(
              widget.torneo.descripcion,
              style: TextStyle(fontSize: 16),
            ),
            Divider(height: 32),
            _buildStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.torneo.estado) {
      case 'abierto':
        return Colors.green;
      case 'en_progreso':
        return Colors.blue;
      case 'completado':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText() {
    switch (widget.torneo.estado) {
      case 'abierto':
        return 'Inscripciones Abiertas';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Finalizado';
      default:
        return 'Próximamente';
    }
  }

  Widget _buildStatistics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.calendar_today,
                label: 'Inicio',
                value:
                    DateFormat('dd/MM/yyyy').format(widget.torneo.fechaInicio),
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.calendar_month,
                label: 'Fin',
                value: DateFormat('dd/MM/yyyy').format(widget.torneo.fechaFin),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.groups,
                label: 'Equipos',
                value:
                    '${widget.torneo.minimoEquipos}/${widget.torneo.maximoEquipos}',
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.attach_money,
                label: 'Inscripción',
                value: '\$${widget.torneo.cuotaInscripcion}',
              ),
            ),
          ],
        ),
        if (widget.torneo.premio != null) ...[
          SizedBox(height: 16),
          _buildPrizeCard(),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeCard() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[300]!, Colors.amber[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.amber[800]),
          SizedBox(width: 8),
          Text(
            'Premio: ${widget.torneo.premio}',
            style: TextStyle(
              color: Colors.amber[900],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final rules = _torneoDetails?['rules'] ?? [];

    if (rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay reglas disponibles',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  const Text(
                    'Reglas del Torneo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(height: 32),
              ...rules
                  .map((rule) => Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rule.toString(),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTab() {
    final standings = _torneoDetails?['standings'] ?? [];

    if (standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tabla de posiciones no disponible',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            columns: [
              DataColumn(label: Text('Pos')),
              DataColumn(label: Text('Equipo')),
              DataColumn(label: Text('PJ')),
              DataColumn(label: Text('G')),
              DataColumn(label: Text('E')),
              DataColumn(label: Text('P')),
              DataColumn(label: Text('GF')),
              DataColumn(label: Text('GC')),
              DataColumn(label: Text('Pts')),
            ],
            rows: standings.map<DataRow>((team) {
              bool isTopThree = team['posicion'] <= 3;
              Color? rowColor = isTopThree ? Colors.blue[50] : null;

              return DataRow(
                color: MaterialStateProperty.all(rowColor),
                cells: [
                  DataCell(_buildPosition(team['posicion'])),
                  DataCell(Text(team['equipo'].toString())),
                  DataCell(Text(team['jugados'].toString())),
                  DataCell(Text(team['ganados'].toString())),
                  DataCell(Text(team['empatados'].toString())),
                  DataCell(Text(team['perdidos'].toString())),
                  DataCell(Text(team['goles_favor'].toString())),
                  DataCell(Text(team['goles_contra'].toString())),
                  DataCell(
                    Text(
                      team['puntos'].toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPosition(int position) {
    Color color;
    IconData? icon;

    switch (position) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown;
        icon = Icons.emoji_events;
        break;
      default:
        return Text(position.toString());
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4),
        Text(position.toString()),
      ],
    );
  }
}
