import 'package:intl/intl.dart';

class MathPartido {
  final int id;
  final String name;
  final String fieldName;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final int currentPlayers;
  final int maxPlayers;
  final double price;
  final String status;

  MathPartido({
    required this.id,
    required this.name,
    required this.fieldName,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.price,
    required this.status,
  });

  String get formattedStartTime {
    final time = DateTime.parse('2024-01-01 $startTime');
    return DateFormat('H:mm').format(time);
  }

  String get formattedEndTime {
    final time = DateTime.parse('2024-01-01 $endTime');
    return DateFormat('H:mm').format(time);
  }

  factory MathPartido.fromJson(Map<String, dynamic> json) {
    return MathPartido(
      id: json['id'],
      name: json['name'],
      fieldName: json['field']['name'],
      scheduleDate: DateTime.parse(json['schedule_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      currentPlayers: json['player_count'],
      maxPlayers: json['max_players'],
      price: double.parse(json['price'].toString()),
      status: json['status'],
    );
  }
}