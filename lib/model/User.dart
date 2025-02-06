class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? codigoPostal;
  final bool? verified;
  final String? createdAt;
  final String? updatedAt;
  final String? nickname; // Puede ser null
  final String? birthDate; // Puede ser null
  final String? position; // Puede ser null
  final String? jerseyNumber; // Puede ser null
  final bool isCapitan;
  final String? apodo; // Puede ser null
  final String? fechaNacimiento; // Puede ser null
  final String? posicion; // Puede ser null
  final String? numeroCamiseta; // Puede ser null
  final String inviteCode;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.codigoPostal,
    this.verified,
    this.createdAt,
    this.updatedAt,
    this.nickname,
    this.birthDate,
    this.position,
    this.jerseyNumber,
    required this.isCapitan,
    this.apodo,
    this.fechaNacimiento,
    this.posicion,
    this.numeroCamiseta,
    required this.inviteCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      codigoPostal: json['codigo_postal'],
      verified: json['verified'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      nickname: json['nickname'] ?? '', // Si es null, usa cadena vacía
      birthDate: json['birth_date'] ?? '',
      position: json['position'] ?? '',
      jerseyNumber: json['jersey_number'] ?? '',
      isCapitan: json['is_captain'] == 1, // Si es 1, es verdadero
      apodo: json['apodo'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] ?? '',
      posicion: json['posicion'] ?? '',
      numeroCamiseta: json['numero_camiseta'] ?? '',
      inviteCode: json['invite_code'],
    );
  }
}
