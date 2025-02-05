import 'package:user_auth_crudd10/model/Miembro.dart';

class Equipo {
  final int id;
  final String nombre;
  final String? logo;
  final String colorUniforme;
  final List<Miembro> miembros;

  Equipo({
    required this.id,
    required this.nombre,
    this.logo,
    required this.colorUniforme,
    required this.miembros,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id'],
      nombre: json['nombre'],
      logo: json['logo'],
      colorUniforme: json['color_uniforme'],
      miembros: (json['miembros'] as List<dynamic>?)
              ?.map((m) => Miembro.fromJson(m))
              .toList() ??
          [],
    );
  }
}
