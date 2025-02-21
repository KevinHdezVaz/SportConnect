 
class PositionsConfig {
  static final Map<String, List<Map<String, dynamic>>> fieldTypePositions = {
    'fut5': [
      {'name': 'Portero', 'icon': 'assets/logos/portero.png'},
      {'name': 'Defensa', 'icon': 'assets/logos/patada.png'},
      {'name': 'Mediocampista', 'icon': 'assets/logos/disparar.png'},
      {'name': 'Delantero', 'icon': 'assets/logos/patear.png'},
      {'name': 'Libre', 'icon': 'assets/logos/voleo.png'},
    ],
    'fut7': [
      {'name': 'Portero', 'icon': 'assets/logos/portero.png'},
      {'name': 'L. Derecho', 'icon': 'assets/logos/patada.png'},
      {'name': 'L. Izquierdo', 'icon': 'assets/logos/patada.png'},
      {'name': 'Mediocampista', 'icon': 'assets/logos/disparar.png'},
      {'name': 'Extremo Derecho', 'icon': 'assets/logos/voleo.png'},
      {'name': 'Extremo Izquierdo', 'icon': 'assets/logos/voleo.png'},
      {'name': 'Delantero', 'icon': 'assets/logos/patear.png'},
    ],
    'fut11': [
      {'name': 'Portero', 'icon': 'assets/logos/portero.png'},
      {'name': 'L. Derecho', 'icon': 'assets/logos/voleo.png'},
      {'name': 'Def. Central Derecho', 'icon': 'assets/logos/patada.png'},
      {'name': 'Def Central Izquierdo', 'icon': 'assets/logos/patada.png'},
      {'name': 'L. Izquierdo', 'icon': 'assets/logos/voleo.png'},
      {'name': 'Medio Defensivo', 'icon': 'assets/logos/patada.png'},
      {'name': 'Medio Derecho', 'icon': 'assets/logos/disparar.png'},
      {'name': 'Medio Central', 'icon': 'assets/logos/disparar.png'},
      {'name': 'Medio Izquierdo', 'icon': 'assets/logos/disparar.png'},
      {'name': 'Delantero Derecho', 'icon': 'assets/logos/patear.png'},
      {'name': 'Delantero Izquierdo', 'icon': 'assets/logos/patear.png'},
    ],
  };

  static List<Map<String, dynamic>> getPositionsForFieldType(String fieldType) {
    // Convertir el tipo de campo a minúsculas y eliminar espacios
    final normalizedFieldType = fieldType.toLowerCase().replaceAll(' ', '');
    return fieldTypePositions[normalizedFieldType] ?? [];
  }
}
