import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final items = [
        OrderItem(
          title: "Producto 1",
          quantity: 2,
          unitPrice: 10.0,
        ),
        OrderItem(
          title: "Producto 2",
          quantity: 1,
          unitPrice: 10.0,
        ),
      ];

      await _paymentService.procesarPago(items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagar con MercadoPago'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _processPayment,
                child: Text('Pagar con MercadoPago'),
              ),
      ),
    );
  }
}
