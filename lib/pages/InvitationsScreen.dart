
import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Notificacion.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/services/NotificationServiceExtension.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';


class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen();

  @override
  _InvitationsScreenState createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  late final EquipoService _equipoService;
  bool _isLoading = true;
  List<Equipo> _invitacionesPendientes = [];

  @override
  void initState() {
    super.initState();
    _equipoService = EquipoService();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      setState(() => _isLoading = true);
      _invitacionesPendientes = await _equipoService.getInvitacionesPendientes();
    } catch (e) {
      _showSnackBar('Error al cargar invitaciones: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _aceptarInvitacion(int equipoId) async {
    try {
      await _equipoService.aceptarInvitacion(equipoId);
      _showSnackBar('Invitación aceptada', Colors.green);
      _loadInvitations();
    } catch (e) {
      _showSnackBar('Error al aceptar invitación: $e', Colors.red);
    }
  }

  Future<void> _rechazarInvitacion(int equipoId) async {
    try {
      await _equipoService.rechazarInvitacion(equipoId);
      _showSnackBar('Invitación rechazada', Colors.orange);
      _loadInvitations();
    } catch (e) {
      _showSnackBar('Error al rechazar invitación: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones Pendientes', style: TextStyle(color: Colors.black),)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invitacionesPendientes.isEmpty
              ? const Center(child: Text('No hay invitaciones', style: TextStyle(color: Colors.black),))
              : ListView.builder(
                  itemCount: _invitacionesPendientes.length,
                  itemBuilder: (context, index) {
                    final invitacion = _invitacionesPendientes[index];
                    return ListTile(
                      title: Text('Invitación a ${invitacion.nombre}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _aceptarInvitacion(invitacion.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rechazarInvitacion(invitacion.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
