class EquipoPartido {
  final int id;
  final String name;
  final int playerCount;
  final List<MatchPlayer> players;
  final String color;
  final String emoji;

  EquipoPartido({
    required this.id,
    required this.name,
    required this.playerCount,
    required this.players,
    required this.color,
    required this.emoji,
  });

  factory EquipoPartido.fromJson(Map<String, dynamic> json) {
    return EquipoPartido(
      id: json['id'],
      name: json['name'],
      playerCount: json['player_count'],
      players: (json['players'] as List)
          .map((player) => MatchPlayer.fromJson(player))
          .toList(),
      color: json['color'],
      emoji: json['emoji'],
    );
  }
}

class MatchPlayer {
  final User user;
  final String position;
  final int equipoPartidoId;

  MatchPlayer({
    required this.user,
    required this.position,
    required this.equipoPartidoId,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    return MatchPlayer(
      user: User.fromJson(json['user']),
      position: json['position'],
      equipoPartidoId: json['equipo_partido_id'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      profileImage: json['profile_image'],
    );
  }
}
