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
  final List<MatchTeam>? teams;
  final DateTime createdAt; // Fecha y hora de creación del partido

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
    required this.createdAt, // Campo requerido
  });

  String get formattedStartTime => startTime.substring(0, 5);
  String get formattedEndTime => endTime.substring(0, 5);

  factory MathPartido.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing match JSON: ${json['id']}');
    debugPrint('VERSIÓN ACTUALIZADA DE MathPartido.fromJson'); // Marca para confirmar
    try {
      final dateStr = json['schedule_date'] as String?; // Permitir null
      final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();

      final startTime = json['start_time'] as String? ?? '00:00:00'; // Permitir null
      final endTime = json['end_time'] as String? ?? '00:00:00'; // Permitir null

      final priceValue = json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0;

      final playerCount = json['player_count'] ?? 0;
      final maxPlayers = json['max_players'] ?? 0;

      // Parsear created_at en UTC y convertir a local si es necesario
      final createdAtStr = json['created_at'] as String?;
      final createdAt = createdAtStr != null
          ? DateTime.parse(createdAtStr).toLocal() // Convertir a la zona horaria local
          : DateTime.now().toLocal(); // Fallback por defecto

      return MathPartido(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Sin nombre',
        gameType: json['game_type'] as String? ?? 'No especificado',
        scheduleDate: date,
        startTime: startTime,
        endTime: endTime,
        price: priceValue,
        playerCount: playerCount,
        maxPlayers: maxPlayers,
        status: json['status'] as String? ?? 'open',
        fieldId: json['field']?['id'] as int?,
        field: json['field'] != null ? Field.fromJson(json['field'] as Map<String, dynamic>) : null,
        createdAt: createdAt, // Usar la fecha de creación parseada
        teams: json['teams'] != null
            ? (json['teams'] as List<dynamic>? ?? [])
                .map((team) => MatchTeam.fromJson(team as Map<String, dynamic>))
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
      createdAt: createdAt, // Mantener createdAt
    );
  }

  String get gameTypeDisplay {
    switch (gameType) {
      case 'fut5':
        return 'Fútbol 5';
      case 'fut7':
        return 'Fútbol 7';
      case 'fut11':
        return 'Fútbol 11';
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