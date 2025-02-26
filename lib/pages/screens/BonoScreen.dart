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

class _BonosScreenState extends State<BonosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true; // Cambiado a true para mostrar carga desde el inicio
  List<Bono> _bonos = [];
  List<UserBono> _misBonos = [];
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(); // Cargar datos al iniciar
  }

  Future<void> _loadData() async {
    try {
      _bonos = await widget.bonoService.getBonos();
      _misBonos = await widget.bonoService.getMisBonos();
    } catch (e) {
      _showSnackBar('Error al cargar los datos: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'Bonos',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade700,
          indicatorWeight: 3,
          padding: EdgeInsets.symmetric(horizontal: 16),
          tabs: [
            Tab(
              child: Text(
                'Disponibles',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Tab(
              child: Text(
                'Mis Bonos',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade700,
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.blue.shade700,
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 60, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'No hay bonos disponibles',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Ahorra con nuestros bonos!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '6 de cada 10 jugadores los prefieren ⚽',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 24),
            AnimatedList(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              initialItemCount: _bonos.length,
              itemBuilder: (context, index, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: BonoCard(
                        bono: _bonos[index],
                        onComprar: () => _comprarBono(_bonos[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMisBonosTab() {
    if (_misBonos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 80,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16),
              Text(
                'No tienes bonos activos',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Compra un bono para comenzar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: Icon(Icons.local_offer),
                label: Text('Ver Bonos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _misBonos.length,
      itemBuilder: (context, index) {
        final userBono = _misBonos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
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
    if (_isLoading) return;

    try {
      if (_misBonos.any((userBono) => userBono.bonoId == bono.id)) {
        _showSnackBar(
          'Ya tienes este bono activo. Espera a que termine.',
          Colors.orange,
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirmar Compra',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black87, fontSize: 16),
              children: [
                TextSpan(text: '¿Comprar el bono '),
                TextSpan(
                  text: bono.tipo,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' por '),
                TextSpan(
                  text: '\$${bono.precio.toStringAsFixed(2)} UYU',
                  style: TextStyle(color: Colors.green.shade700),
                ),
                TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Comprar',
                  style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _procesarPago(bono);
      }
    } catch (e) {
      _showSnackBar('Error al verificar bonos: $e', Colors.red);
    }
  }

  Future<void> _procesarPago(Bono bono) async {
    setState(() => _isLoading = true);
    try {
      final items = [
        OrderItem(
          title: "Bono - ${bono.titulo}",
          quantity: 1,
          unitPrice: bono.precio,
        ),
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

      if (paymentResult['status'] == PaymentStatus.success ||
          paymentResult['status'] == PaymentStatus.approved) {
        final userBono = await widget.bonoService.comprarBono(
          bonoId: bono.id,
          paymentId: paymentResult['paymentId'],
          orderId: paymentResult['orderId'],
        );
        setState(() => _misBonos.add(userBono));
        _showSnackBar('¡Bono comprado exitosamente!', Colors.green);
        _tabController.animateTo(1);
      } else {
        throw Exception('Pago no aprobado: ${paymentResult['status']}');
      }
    } catch (e) {
      if (e.toString().contains('Este pago ya ha sido procesado')) {
        await _loadData();
        _showSnackBar('¡Bono ya registrado correctamente!', Colors.green);
        _tabController.animateTo(1);
      } else {
        _showSnackBar('Error al procesar el pago: $e', Colors.red);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarQR(UserBono userBono) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tu Código QR',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userBono.codigoReferencia,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Código: ${userBono.codigoReferencia}',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Muestra este código en la cancha',
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text('Cerrar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navToReservar(UserBono userBono) {
    _showSnackBar('Navegando a reservas...', Colors.blue);
    // Implementa aquí la navegación real si es necesario
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
