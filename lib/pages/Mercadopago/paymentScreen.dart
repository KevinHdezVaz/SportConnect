
// lib/screens/payment_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
 
class PaymentScreen extends StatefulWidget {
  final List<OrderItem> items;
  final String customerName;
  final String customerEmail;

  const PaymentScreen({
    Key? key,
    required this.items,
    required this.customerName,
    required this.customerEmail,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  StreamSubscription? _paymentStatusSubscription;

  @override
  void initState() {
    super.initState();
    _setupPaymentListener();
  }

 void _setupPaymentListener() {
  _paymentStatusSubscription = paymentStatusController.stream.listen((status) {
    switch (status) {
      case PaymentStatus.success:
      case PaymentStatus.approved: // Manejar el estado aprobado como éxito
        _onPaymentSuccess();
        break;
      case PaymentStatus.failure:
        _onPaymentFailure();
        break;
      case PaymentStatus.pending:
        _onPaymentPending();
        break;
      default:
        debugPrint('Estado de pago desconocido: $status');
    }
  });
}

void _onPaymentSuccess() {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡Pago aprobado!')),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BookingScreen()),
    );
  }
} 


  void _onPaymentFailure() {
    if (mounted) {
      Navigator.of(context).pop(false); // Retornar fallo
    }
  }

  void _onPaymentPending() {
    if (mounted) {
      Navigator.of(context).pop('pending'); // Retornar pendiente
    }
  }

  Future<void> _initializePayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final additionalData = {
        'customer': {
          'name': widget.customerName,
          'email': widget.customerEmail,
        },
        'external_reference': 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
      };

      await _paymentService.procesarPago(
        context,
        widget.items,
        additionalData: additionalData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _paymentStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold(
      0.0,
      (sum, item) => sum + (21 * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Procesar Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de la orden',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            return ListTile(
                              title: Text("asdfa"),
                              subtitle: Text('Cantidad: ${item.quantity}'),
                              trailing: Text(
                                '\$${(21 * item.quantity).toStringAsFixed(2)}',
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(),
                      ListTile(
                        title: Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _initializePayment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Pagar \$${total.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}