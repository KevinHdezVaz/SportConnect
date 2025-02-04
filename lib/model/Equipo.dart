class Equipo {
  final int id;
  final String nombre;
  final String? logo;
  final String colorUniforme;
  final String nombreCapitan;
  final String telefonoCapitan;
  final String emailCapitan;

  Equipo({
    required this.id,
    required this.nombre,
    this.logo,
    required this.colorUniforme,
    required this.nombreCapitan,
    required this.telefonoCapitan,
    required this.emailCapitan,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id'],
      nombre: json['nombre'],
      logo: json['logo'],
      colorUniforme: json['color_uniforme'],
      nombreCapitan: json['nombre_capitan'],
      telefonoCapitan: json['telefono_capitan'],
      emailCapitan: json['email_capitan'],
    );
  }
}
