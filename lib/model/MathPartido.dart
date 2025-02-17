import 'package:user_auth_crudd10/model/field.dart';

class MathPartido {
  final int id;
  final String name;
  final DateTime scheduleDate; // Esta es la clave
  final String startTime;
  final String endTime;

  final double price;
  final int playerCount;
  final int maxPlayers;
  final String status;
  final int? fieldId;
  final Field? field;

  MathPartido({
    required this.id,
    required this.name,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.playerCount,
    required this.maxPlayers,
    required this.status,
    this.fieldId,
    this.field,
  });

  String get formattedStartTime => startTime.substring(0, 5);
  String get formattedEndTime => endTime.substring(0, 5);
  factory MathPartido.fromJson(Map<String, dynamic> json) {
    print('Parsing schedule_date: ${json['schedule_date']}'); // Depuración
    return MathPartido(
      id: json['id'],
      name: json['name'],
      scheduleDate: DateTime.parse(
          json['schedule_date']), // Asegúrate de que esto sea correcto
      startTime: json['start_time'],
      endTime: json['end_time'],
      price: double.parse(json['price'].toString()),
      playerCount: json['player_count'],
      maxPlayers: json['max_players'],
      status: json['status'],
      fieldId: json['field_id'],
      field: json['field'] != null ? Field.fromJson(json['field']) : null,
    );
  }
  MathPartido toMathPartido() {
    return MathPartido(
      id: id,
      name: name,
      playerCount: playerCount,
      maxPlayers: maxPlayers,
      scheduleDate: scheduleDate,
      startTime: startTime,
      endTime: endTime,
      price: price,
      status: status,
      fieldId: fieldId,
    );
  }
}
