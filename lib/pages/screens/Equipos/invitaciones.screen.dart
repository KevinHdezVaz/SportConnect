// lib/screens/equipos/invitaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/pages/others/profile_page.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/detalle_equipo.screen.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';

class InvitacionesScreen extends StatefulWidget {
  @override
  _InvitacionesScreenState createState() => _InvitacionesScreenState();
}

class _InvitacionesScreenState extends State<InvitacionesScreen> {
  final _equipoService = EquipoService();
  bool _isLoading = true;
  List<Equipo> _invitaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarInvitaciones();
  }

  Future<void> _cargarInvitaciones() async {
    try {
      setState(() => _isLoading = true);
      final invitaciones = await _equipoService.getInvitacionesPendientes();
      setState(() => _invitaciones = invitaciones);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar invitaciones: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitaciones de Equipo'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _invitaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes invitaciones pendientes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _invitaciones.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final equipo = _invitaciones[index];
                    return Card(
                      elevation: 10,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: equipo.logo != null
                                  ? NetworkImage(equipo.logo!)
                                  : null,
                              child: equipo.logo == null
                                  ? Text(equipo.nombre[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(
                              equipo.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              'Color de uniforme: ${equipo.colorUniforme}', style: TextStyle(color: Colors.black),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rechazarInvitacion(equipo.id),
                                    child: Text('Rechazar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _aceptarInvitacion(equipo.id),
                                    child: Text('Aceptar', style: TextStyle(color: Colors.white),),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _aceptarInvitacion(int equipoId) async {
    try {
      await _equipoService.aceptarInvitacion(equipoId);
      await _cargarInvitaciones();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitación aceptada')
        ,
            backgroundColor: Colors.green,  
            ),
      );
      
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfilePage(),
        ),
      );

      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar invitación: $e')),
      );
    }
  }

  Future<void> _rechazarInvitacion(int equipoId) async {
    try {
      await _equipoService.rechazarInvitacion(equipoId);
      await _cargarInvitaciones();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitación rechazada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar invitación: $e')),
      );
    }
  }
}