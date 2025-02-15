import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MathPartido match;

  const MatchDetailsScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Partido'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Información del partido
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.match.fieldName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(widget.match.scheduleDate),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 8),
                      Text('${widget.match.formattedStartTime} - ${widget.match.formattedEndTime}'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Precio por jugador: \$${widget.match.price}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Equipos
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Equipo Local
                  _buildTeamSection(
                    teamName: 'Equipo Verde 🦁',
                    availablePositions: 8,
                    players: [
                      _PlayerInfo(name: 'H. Vásquez', position: 'Portero', image: 'url_imagen'),
                      _PlayerInfo(name: 'Disponible', position: 'L.Derecho'),
                      _PlayerInfo(name: 'Disponible', position: 'L.Izquierdo'),
                    ],
                    teamColor: Colors.green,
                  ),
                  SizedBox(height: 16),
                  // Equipo Visitante
                  _buildTeamSection(
                    teamName: 'Equipo Rojo 🍎',
                    availablePositions: 9,
                    players: [
                      _PlayerInfo(name: 'Disponible', position: 'Portero'),
                      _PlayerInfo(name: 'Disponible', position: 'L.Derecho'),
                      _PlayerInfo(name: 'Disponible', position: 'L.Izquierdo'),
                    ],
                    teamColor: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              _showJoinTeamDialog(context);
            },
            child: Text('Unirme al Partido'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection({
    required String teamName,
    required int availablePositions,
    required List<_PlayerInfo> players,
    required Color teamColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                teamName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: teamColor,
                ),
              ),
              Text(
                '$availablePositions Plazas',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: player.image != null
                      ? NetworkImage(player.image!)
                      : null,
                  child: player.image == null
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(player.name),
                subtitle: Text(player.position),
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showJoinTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selecciona tu equipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: Text('Equipo Verde'),
              subtitle: Text('8 plazas disponibles'),
              onTap: () {
                Navigator.pop(context);
                _showPositionDialog(context, 'verde');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: Text('Equipo Rojo'),
              subtitle: Text('9 plazas disponibles'),
              onTap: () {
                Navigator.pop(context);
                _showPositionDialog(context, 'rojo');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPositionDialog(BuildContext context, String team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selecciona tu posición'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Portero'),
              onTap: () {
                // Lógica para unirse como portero
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('L.Derecho'),
              onTap: () {
                // Lógica para unirse como L.Derecho
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('L.Izquierdo'),
              onTap: () {
                // Lógica para unirse como L.Izquierdo
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerInfo {
  final String name;
  final String position;
  final String? image;

  _PlayerInfo({
    required this.name,
    required this.position,
    this.image,
  });
}