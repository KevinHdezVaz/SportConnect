import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/Miembro.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/ChatTabWidget.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/InvitarPorCodigoScreen.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';

class DetalleEquipoScreen extends StatefulWidget {
  final Equipo equipo;
  final int userId;

  DetalleEquipoScreen({required this.equipo, required this.userId});

  @override
  _DetalleEquipoScreenState createState() => _DetalleEquipoScreenState();
}

class _DetalleEquipoScreenState extends State<DetalleEquipoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _equipoService = EquipoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
        _tabController.addListener(_handleTabSelection);
  }

 @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }
  void _handleTabSelection() {
    // Forzar rebuild cuando cambia la tab para actualizar el FAB
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white), // Cambia el icono aquí
          onPressed: () {
            Navigator.pop(context); // Acción al presionar el botón
          },
        ),
        title: Text(
          widget.equipo.nombre,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent, // Hace el AppBar transparente
        elevation: 0, // Sin sombra
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 127, 205, 234),
                Color.fromARGB(255, 104, 151, 193),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.info), text: 'Información'),
            Tab(icon: Icon(Icons.group), text: 'Miembros'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Torneos'),
            Tab(icon: Icon(Icons.message), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildMiembrosTab(),
          _buildTorneosTab(),
                    ChatTab(
                      equipoId: widget.equipo.id ,
                      userId: widget.userId ,
                    ),

        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildInfoTab() {
    final imageUrl = widget.equipo.logo != null
        ? 'https://proyect.aftconta.mx/storage/${widget.equipo.logo}'
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Hero(
              tag: 'equipo_${widget.equipo.id}',
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                          loadingBuilder: (context, child, loadingProgress) {
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
                            return Center(
                              child: Text(
                                widget.equipo.nombre[0].toUpperCase(),
                                style: TextStyle(
                                    fontSize: 50, color: Colors.blueAccent),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.equipo.nombre[0].toUpperCase(),
                          style:
                              TextStyle(fontSize: 50, color: Colors.blueAccent),
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 24),
          _infoCard(
            'Información del Equipo',
            [
              _infoRow('Nombre', widget.equipo.nombre),
              _infoRow('Color del uniforme', widget.equipo.colorUniforme),
              _infoRow('Miembros', '${widget.equipo.miembros.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiembrosTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.equipo.miembros.length,
            itemBuilder: (context, index) {
              final miembro = widget.equipo.miembros[index];
              final esCapitan = miembro.pivot.rol == 'capitan';
              final pendiente = miembro.pivot.estado == 'pendiente';

              final imageUrl = miembro.profileImage != null
                  ? 'https://proyect.aftconta.mx/storage/${miembro.profileImage}'
                  : null;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null
                        ? Text(miembro.name[0].toUpperCase(),
                            style: TextStyle(color: Colors.white))
                        : null,
                    backgroundColor: Colors.blueAccent,
                  ),
                  title: Row(
                    children: [
                      Text(
                        miembro.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: pendiente ? Colors.grey : Colors.black,
                        ),
                      ),
                      if (esCapitan)
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child:
                              Icon(Icons.stars, size: 16, color: Colors.amber),
                        ),
                      if (pendiente)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pendiente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    miembro.email!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  trailing: !esCapitan && !pendiente
                      ? PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar del equipo'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'eliminar') {
                              _confirmarEliminarMiembro(miembro);
                            }
                          },
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTorneosTab() {
    return Center(
      child: Text(
        'Próximamente: Torneos',
        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // No mostrar el FAB si estamos en la pestaña de chat (índice 3)
    if (_tabController.index == 3) return SizedBox.shrink();

    final esCaptain = widget.equipo.miembros
        .any((m) => m.pivot.rol == 'capitan' && m.id == widget.userId);

    if (!esCaptain) return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'btnInvitarCodigo',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvitarPorCodigoScreen(equipoId: widget.equipo.id),
              ),
            );
          },
          icon: Icon(Icons.group, color: Colors.white),
          label: Text('Invitar jugadores', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoInvitarMiembro() async {
    final emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invitar miembro'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email del jugador',
            hintText: 'ejemplo@email.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, emailController.text),
            child: Text('Invitar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _equipoService.invitarMiembro(
          widget.equipo.id,
          result,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitación enviada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmarEliminarMiembro(Miembro miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar miembro'),
        content:
            Text('¿Estás seguro de eliminar a ${miembro.name} del equipo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _equipoService.eliminarMiembro(
          widget.equipo.id,
          miembro.id,
        );

        setState(() {
          widget.equipo.miembros.removeWhere((m) => m.id == miembro.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Miembro eliminado')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
  
  
}
