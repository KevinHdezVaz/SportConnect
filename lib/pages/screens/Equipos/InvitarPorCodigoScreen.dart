import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/User.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';

class InvitarPorCodigoScreen extends StatefulWidget {
  final int equipoId;
  InvitarPorCodigoScreen({required this.equipoId});

  @override
  State<InvitarPorCodigoScreen> createState() => _InvitarPorCodigoScreenState();
}

class _InvitarPorCodigoScreenState extends State<InvitarPorCodigoScreen> {
  final _codigoController = TextEditingController();
  final _equipoService = EquipoService();
  bool _isLoading = false;
  bool _isSearching = false;  
  User? _usuarioEncontrado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invitar Jugador', style: TextStyle(color: Colors.black),)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                   Expanded(
  child: TextField(
    controller: _codigoController,
    style: TextStyle(color: Colors.black),  
    decoration: InputDecoration(
      labelText: 'Código del jugador',
      labelStyle: TextStyle(color: Colors.black),  
      hintText: 'Ingresa el código de 8 dígitos',
      hintStyle: TextStyle(color: Colors.grey), 
      prefixIcon: Icon(Icons.key, color: Colors.green), 
       
    ),
  ),
),

                    SizedBox(width: 10),
                    _isSearching
                        ? CircularProgressIndicator() 
                        : ElevatedButton(
                            onPressed: _buscarUsuario,
                            child: Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold),),
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            if (_usuarioEncontrado != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _usuarioEncontrado!.profileImage != null
                        ? NetworkImage(
                            'https://proyect.aftconta.mx/storage/${_usuarioEncontrado!.profileImage}',
                          )
                        : null,
                    child: _usuarioEncontrado!.profileImage == null
                        ? Text(_usuarioEncontrado!.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(_usuarioEncontrado!.name, style: TextStyle(color: Colors.black),),
                  subtitle: Text(_usuarioEncontrado!.email!, style: TextStyle(color: Colors.black)),
                  trailing: IconButton(
                    icon: _isLoading
                        ? CircularProgressIndicator()
                        : Icon(Icons.person_add, color: Colors.green),
                    onPressed: _isLoading ? null : _invitarJugador,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarUsuario() async {
    if (_codigoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa un código')),
      );
      return;
    }

    setState(() {
      _isSearching = true; 
      _isLoading = true;
    });

    try {
      final usuario = await _equipoService.buscarUsuarioPorCodigo(
        codigo: _codigoController.text,
      );
      setState(() => _usuarioEncontrado = usuario);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _usuarioEncontrado = null);
    } finally {
      setState(() {
        _isSearching = false; 
        _isLoading = false;
      });
    }
  }

  Future<void> _invitarJugador() async {
    setState(() => _isLoading = true);

    try {
      await _equipoService.invitarPorCodigo(
        equipoId: widget.equipoId,
        codigo: _codigoController.text,
      );

      Navigator.pop(context);
     ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'Jugador invitado exitosamente, espera a que acepte la invitación.',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    backgroundColor: Colors.green,  
   ),
);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}