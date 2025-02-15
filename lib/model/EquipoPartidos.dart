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
}