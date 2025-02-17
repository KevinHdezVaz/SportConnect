import 'package:user_auth_crudd10/model/OrderItem.dart';

class Order {
  final List<OrderItem> items;
  final double total;
  final String status;
  final String? preferenceId;
  final String? paymentId;
  final String? currencyId;

  Order({
    required this.items,
    required this.total,
    this.status = 'pending',
    this.preferenceId,
    this.paymentId,
    this.currencyId = 'MXN',
  });
}
