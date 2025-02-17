import 'package:user_auth_crudd10/model/EquipoPartidos.dart';

class MatchTeam {
  final int id;
  final String name;
  final String? color; // Hacerlo opcional
  final String? emoji; // Hacerlo opcional
  final int playerCount;
  final int maxPlayers;
  final List<TeamPlayer> players;

  MatchTeam({
    required this.id,
    required this.name,
    this.color,
    this.emoji,
    required this.playerCount,
    required this.maxPlayers,
    required this.players,
  });

  factory MatchTeam.fromJson(Map<String, dynamic> json) {
    return MatchTeam(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      emoji: json['emoji'],
      playerCount: json['player_count'] ?? 0,
      maxPlayers: json['max_players'] ?? 7,
      players: json['players'] != null
          ? List<TeamPlayer>.from(
              (json['players'] as List).map((x) => TeamPlayer.fromJson(x)))
          : [],
    );
  }
}

class TeamPlayer {
  final User? user; // Hacerlo opcional
  final String position;
  final int equipoPartidoId;

  TeamPlayer({
    this.user,
    required this.position,
    required this.equipoPartidoId,
  });

  factory TeamPlayer.fromJson(Map<String, dynamic> json) {
    return TeamPlayer(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      position: json['position'] ?? '',
      equipoPartidoId: json['equipo_partido_id'] ?? 0,
    );
  }
}
