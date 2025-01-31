import 'dart:convert';

class Booking {
  final int id;
  final int userId;
  final int fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final bool isRecurring;
  final String? cancellationReason;
  final bool allowJoining;
  final int? playersNeeded;
  final List<dynamic> playerList;

  Booking({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.isRecurring,
    this.cancellationReason,
    required this.allowJoining,
    this.playersNeeded,
    required this.playerList,
  });

  // Convierte los datos JSON a una instancia de Booking
  factory Booking.fromJson(Map<String, dynamic> json) {
    List<dynamic> playerList;

    print('Parsing booking: $json'); // Añade este print

    if (json['player_list'] == null) {
      playerList = [];
    } else if (json['player_list'] is String) {
      try {
        // Intenta parsear directamente el JSON
        playerList = json['player_list'] is String
            ? (jsonDecode(json['player_list']) as List?) ?? []
            : (json['player_list'] as List?) ?? [];
      } catch (e) {
        print('Error parsing player_list: $e');
        playerList = [];
      }
    } else if (json['player_list'] is List) {
      playerList = json['player_list'];
    } else {
      playerList = [];
    }

    return Booking(
      id: json['id'],
      userId: json['user_id'],
      fieldId: json['field_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      isRecurring: json['is_recurring'] == 1,
      cancellationReason: json['cancellation_reason'],
      allowJoining: json['allow_joining'] == 1,
      playersNeeded: json['players_needed'],
      playerList: playerList,
    );
  }

  // Convierte una instancia de Booking a un mapa (para enviar a una API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'field_id': fieldId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'is_recurring': isRecurring ? 1 : 0,
      'cancellation_reason': cancellationReason,
      'allow_joining': allowJoining ? 1 : 0,
      'players_needed': playersNeeded,
      'player_list': jsonEncode(playerList),
    };
  }

  // Método toString para una mejor visualización en JSON o cuando se imprime
  @override
  String toString() {
    return 'Booking(id: $id, userId: $userId, fieldId: $fieldId, startTime: $startTime, endTime: $endTime, totalPrice: $totalPrice, status: $status, paymentStatus: $paymentStatus, paymentMethod: $paymentMethod, isRecurring: $isRecurring, cancellationReason: $cancellationReason, allowJoining: $allowJoining, playersNeeded: $playersNeeded, playerList: $playerList)';
  }
}