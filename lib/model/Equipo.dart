import 'package:user_auth_crudd10/model/Miembro.dart';

class Equipo {
  final int id;
  final String nombre;
  final String? logo;
  final String colorUniforme;
  final bool esAbierto;
  final int plazasDisponibles;
  final List<Miembro> miembros;

  Equipo({
    required this.id,
    required this.nombre,
    this.logo,
    required this.colorUniforme,
    required this.esAbierto,
    required this.plazasDisponibles,
    required this.miembros,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    try {
      return Equipo(
        id: json['id'] ?? 0,
        nombre: json['nombre']?.toString() ?? '', // Convertir a String de forma segura
        logo: json['logo']?.toString(), // Ya es nullable
        colorUniforme: json['color_uniforme']?.toString() ?? '',
        esAbierto: (json['es_abierto'] == 1 || json['es_abierto'] == true),
        plazasDisponibles: json['plazas_disponibles'] ?? 0,
        miembros: (json['miembros'] as List<dynamic>?)?.map((miembro) {
          if (miembro is Map<String, dynamic>) {
            return Miembro.fromJson(miembro);
          }
          throw FormatException('Formato de miembro inválido: $miembro');
        }).toList() ?? [],
      );
    } catch (e, stack) {
      print('Error parseando equipo: $e');
      print('Stack trace: $stack');
      print('JSON problemático: $json');
      rethrow;
    }
  }
}