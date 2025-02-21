import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';

class MathPartido {
  final int id;
  final String name;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final String gameType;
  final double price;
  final int playerCount;
  final int maxPlayers;
  final String status;
  final int? fieldId;
  final Field? field;
  final List<MatchTeam>? teams; // Agregado para manejar equipos

  MathPartido({
    required this.id,
    required this.name,
    required this.gameType,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.playerCount,
    required this.maxPlayers,
    required this.status,
    this.fieldId,
    this.field,
    this.teams,
  });

  String get formattedStartTime => startTime.substring(0, 5);
  String get formattedEndTime => endTime.substring(0, 5);

  factory MathPartido.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing match JSON: ${json['id']}');
    debugPrint(
        'VERSIÓN ACTUALIZADA DE MathPartido.fromJson'); // Marca para confirmar
    try {
      final dateStr = json['schedule_date'] as String?; // Permitir null
      final date =
          dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();

      final startTime =
          json['start_time'] as String? ?? '00:00:00'; // Permitir null
      final endTime =
          json['end_time'] as String? ?? '00:00:00'; // Permitir null

      final priceValue = json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0;

      final playerCount = json['player_count'] ?? 0;
      final maxPlayers = json['max_players'] ?? 0;

      return MathPartido(
        id: json['id'],
        name: json['name'] ?? 'Sin nombre',
        gameType: json['game_type'] ?? 'No especificado',
        scheduleDate: date,
        startTime: startTime,
        endTime: endTime,
        price: priceValue,
        playerCount: playerCount,
        maxPlayers: maxPlayers,
        status: json['status'] ?? 'open',
        fieldId: json['field']?['id'],
        field: json['field'] != null ? Field.fromJson(json['field']) : null,
        teams: json['teams'] != null
            ? (json['teams'] as List)
                .map((team) => MatchTeam.fromJson(team))
                .toList()
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing MathPartido ID: ${json['id']}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  MathPartido toMathPartido() {
    return MathPartido(
      id: id,
      name: name,
      gameType: gameType,
      playerCount: playerCount,
      maxPlayers: maxPlayers,
      scheduleDate: scheduleDate,
      startTime: startTime,
      endTime: endTime,
      price: price,
      status: status,
      fieldId: fieldId,
      field: field,
      teams: teams,
    );
  }

  String get gameTypeDisplay {
    switch (gameType) {
      case 'fut5':
        return 'Fútbol 5';
      case 'fut7':
        return 'Fútbol 7';
      default:
        return 'No especificado';
    }
  }

  String get formattedDate {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(scheduleDate);
  }

  bool get hasEnded {
    final now = DateTime.now();
    final matchDateTime = DateTime(
      scheduleDate.year,
      scheduleDate.month,
      scheduleDate.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );
    return now.isAfter(matchDateTime);
  }
}
