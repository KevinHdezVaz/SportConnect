import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/TeamPlayer.dart';

class MatchTeam {
  final int id;
  final String name;
  final String color;
  final String emoji;
  final int playerCount;
  final String gameType;  
  final int maxPlayers;
  final List<TeamPlayer> players;

  MatchTeam({
    required this.id,
    required this.name,
            required this.gameType,  // Agregado al constructor

    required this.color,
    required this.emoji,
    required this.playerCount,
    required this.maxPlayers,
    required this.players,
  });

 factory MatchTeam.fromJson(Map<String, dynamic> json) {
    debugPrint('Parseando equipo: ${json['name']}');
    debugPrint('Jugadores raw: ${json['players']}');
    
    var playersList = (json['players'] as List?)?.map((playerJson) {
      try {
        return TeamPlayer.fromJson(playerJson);
      } catch (e) {
        debugPrint('Error parseando jugador: $e');
        return null;
      }
    }).whereType<TeamPlayer>().toList() ?? [];

    debugPrint('Jugadores parseados: ${playersList.length}');

    return MatchTeam(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
                  gameType: json['game_type'] ?? 'No especificado',  // Agregado al fromJson

      color: json['color'] ?? '',
      emoji: json['emoji'] ?? '⚽',
      playerCount: json['player_count'] ?? 0,
      maxPlayers: json['max_players'] ?? 0,
      players: playersList,
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
  
}