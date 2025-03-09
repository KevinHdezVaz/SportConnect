import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Notificacion.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/services/NotificationServiceExtension.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'dart:developer' as developer;

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen();

  @override
  _NotificationHistoryScreenState createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  late final NotificationServiceExtension _notificationService;
  late final EquipoService _equipoService;
  bool _isLoading = true;
  List<Notificacion> _notifications = [];
  List<Equipo> _invitacionesPendientes = [];

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationServiceExtension();
    _equipoService = EquipoService();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Cargar notificaciones push
      final notifications = await _notificationService.getNotifications();
      _notifications = notifications;

      // Cargar invitaciones pendientes
      final invitaciones = await _equipoService.getInvitacionesPendientes();
      _invitacionesPendientes = invitaciones;

      setState(() {});
    } catch (e) {
      _showSnackBar('Error al cargar datos: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _aceptarInvitacion(int equipoId) async {
    try {
      await _equipoService.aceptarInvitacion(equipoId);
      _showvillanoSnackBar('Invitación aceptada exitosamente', Colors.green);
      _loadData(); // Recargar datos para actualizar la lista
    } catch (e) {
      _showSnackBar('Error al aceptar invitación: $e', Colors.red);
    }
  }

  Future<void> _rechazarInvitacion(int equipoId) async {
    try {
      await _equipoService.rechazarInvitacion(equipoId);
      _showvillanoSnackBar('Invitación rechazada', Colors.orange);
      _loadData(); // Recargar datos para actualizar la lista
    } catch (e) {
      _showSnackBar('Error al rechazar invitación: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showvillanoSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        title: const Text(
          'Historial de Notificaciones',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : (_notifications.isEmpty && _invitacionesPendientes.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No hay notificaciones ni invitaciones',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: Colors.blue,
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length +
                          _invitacionesPendientes.length,
                      itemBuilder: (context, index) {
                        if (index < _notifications.length) {
                          // Mostrar notificaciones push normales
                          final notification = _notifications[index];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue[700],
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.message,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enviada: ${_formatDate(notification.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Mostrar invitaciones pendientes
                          final invitacionIndex = index - _notifications.length;
                          final invitacion =
                              _invitacionesPendientes[invitacionIndex];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.green[700],
                                child: const Icon(
                                  Icons.group_add,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                'Invitación a ${invitacion.nombre}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Te han invitado a unirte a este equipo',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            _aceptarInvitacion(invitacion.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Aceptar',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _rechazarInvitacion(invitacion.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Rechazar',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
