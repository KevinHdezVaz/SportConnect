import 'package:user_auth_crudd10/model/WalletTransaction.dart';

class Wallet {
  double balance;
  int points;
  List<WalletTransaction> transactions;
  
  Wallet({
    required this.balance,
    required this.points,
    required this.transactions,
  });
  
  factory Wallet.fromJson(Map<String, dynamic> json) {
    // Manejo más robusto para el balance
    double balanceValue;
    final balanceRaw = json['balance'];
    if (balanceRaw is num) {
      balanceValue = balanceRaw.toDouble();
    } else if (balanceRaw is String) {
      balanceValue = double.tryParse(balanceRaw) ?? 0.0;
    } else {
      balanceValue = 0.0;
    }
    
    // Manejo más robusto para los puntos
    int pointsValue;
    final pointsRaw = json['points'];
    if (pointsRaw is int) {
      pointsValue = pointsRaw;
    } else if (pointsRaw is String) {
      pointsValue = int.tryParse(pointsRaw) ?? 0;
    } else if (pointsRaw is double) {
      pointsValue = pointsRaw.toInt();
    } else {
      pointsValue = 0;
    }
    
    return Wallet(
      balance: balanceValue,
      points: pointsValue,
      transactions: (json['transactions'] as List? ?? [])
          .map((t) => WalletTransaction.fromJson(t))
          .toList(),
    );
  }
}