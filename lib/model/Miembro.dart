class Miembro {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final bool verified;
  final MiembroPivot pivot;

  Miembro({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.verified,
    required this.pivot,
  });

  factory Miembro.fromJson(Map<String, dynamic> json) {
    return Miembro(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      verified: json['verified'] ?? false,
      pivot: MiembroPivot.fromJson(json['pivot']),
    );
  }
}

class MiembroPivot {
  final int equipoId;
  final int userId;
  final String rol;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  MiembroPivot({
    required this.equipoId,
    required this.userId,
    required this.rol,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MiembroPivot.fromJson(Map<String, dynamic> json) {
    return MiembroPivot(
      equipoId: json['equipo_id'],
      userId: json['user_id'],
      rol: json['rol'],
      estado: json['estado'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
