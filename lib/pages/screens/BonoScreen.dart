import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/Bonos.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/model/UserBono.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';
import 'package:user_auth_crudd10/pages/screens/BonoCard.dart';
import 'package:user_auth_crudd10/services/BonoService.dart';

class BonosScreen extends StatefulWidget {
  final BonoService bonoService;

  const BonosScreen({required this.bonoService, Key? key}) : super(key: key);

  @override
  _BonosScreenState createState() => _BonosScreenState();
}

class _BonosScreenState extends State<BonosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Bono> _bonos = [];
  List<UserBono> _misBonos = [];
final PaymentService _paymentService = PaymentService();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _loadData();
    }
  }
Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _bonos = await widget.bonoService.getBonos();
      _misBonos = await widget.bonoService.getMisBonos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bonos',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
         
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: [
                                  Tab(child: Text('Bonos Disponibles', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))),
                                  Tab(child: Text('Mis Bonos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))),
 
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.green,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBonosDisponiblesTab(),
                  _buildMisBonosTab(),
                ],
              ),
            ),
      
    );
  }

  Widget _buildBonosDisponiblesTab() {
    if (_bonos.isEmpty) {
      return Center(
        child: Text('No hay bonos disponibles actualmente'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Compra un bono y ahorra dinero',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              '6 de cada 10 jugadores los prefieren ¡No te pierdas esta increíble oferta! 💰 💪 ⚽',
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ..._bonos.map((bono) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: BonoCard(
                bono: bono,
                onComprar: () => _comprarBono(bono),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMisBonosTab() {
    if (_misBonos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No tienes bonos activos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Compra un bono para comenzar a jugar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              child: Text('Ver Bonos Disponibles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _misBonos.length,
      itemBuilder: (context, index) {
        final userBono = _misBonos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: UserBonoCard(
            userBono: userBono,
            onVerQR: () => _mostrarQR(userBono),
            onReservar: () => _navToReservar(userBono),
          ),
        );
      },
    );
  }

void _comprarBono(Bono bono) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comprar Bono'),
        content: Text('¿Estás seguro de comprar el bono ${bono.tipo} por ${bono.precio.toStringAsFixed(2)} MXN?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _procesarPago(bono);
    }
  }

 Future<void> _procesarPago(Bono bono) async {
  if (_isLoading) return; // Evitar múltiples ejecuciones simultáneas

  setState(() => _isLoading = true);

  try {
    final items = [
      OrderItem(title: "Bono - ${bono.titulo}", quantity: 1, unitPrice: bono.precio),
    ];

    final paymentResult = await _paymentService.procesarPago(
      context,
      items,
      additionalData: {
        'reference_id': bono.id,
        'customer': {'name': 'Usuario', 'email': 'usuario@ejemplo.com'},
      },
      type: 'bono',
    );

    debugPrint('Payment result: $paymentResult');
    debugPrint('Type de orderId: ${paymentResult['orderId'].runtimeType}');

    // Verificar si el bono ya existe para este usuario y bono_id
    final existingUserBono = await widget.bonoService.getMisBonos().then((list) {
      return list.firstWhere(
        (userBono) => userBono.bonoId == bono.id,
       );
    }) as UserBono?; // Aseguramos que puede ser null

    if (existingUserBono != null) {
      throw Exception('Este bono ya fue comprado previamente');
    }

    if (paymentResult['status'] == PaymentStatus.success || paymentResult['status'] == PaymentStatus.approved) {
      final userBono = await widget.bonoService.comprarBono(
        bonoId: bono.id,
        paymentId: paymentResult['paymentId'],
        orderId: paymentResult['orderId'],
      );
      setState(() => _misBonos.add(userBono));
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Bono comprado exitosamente!'), backgroundColor: Colors.green),
        );
        _tabController.animateTo(1);
      });
    } else {
      throw Exception('Estado del pago: ${paymentResult['status']}');
    }
  } catch (e) {
    debugPrint('Excepción capturada: $e');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el pago: $e'), backgroundColor: Colors.red),
      );
    });
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _mostrarQR(UserBono userBono) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Código QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.black)),
              child: Center(
                child: Text(
                  userBono.codigoReferencia,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Código: ${userBono.codigoReferencia}'),
            SizedBox(height: 8),
            Text(
              'Presenta este código al responsable de la cancha',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _navToReservar(UserBono userBono) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a la pantalla de reservas...')),
    );
  }
 

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}