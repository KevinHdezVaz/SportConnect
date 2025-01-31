import 'dart:convert'; // Asegúrate de importar esto

class Field {
  final int id;
  final String name;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final bool is_active;
  final String type;
  final dynamic available_hours; // Puede ser un Map o List
  final List<String>? amenities;
  final List<String>? images;
  final String price_per_match;

  Field({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.is_active,
    required this.type,
    required this.available_hours,
    this.amenities,
    this.images,
    required this.price_per_match,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      is_active: json['is_active'] == 1, // Convertir el 1/0 a boolean
      type: json['type'],
      available_hours: json['available_hours'] != null
          ? jsonDecode(json['available_hours']) // Parsear la cadena JSON
          : null,
      amenities: json['amenities'] != null
          ? List<String>.from(
              jsonDecode(json['amenities'])) // Parsear la cadena JSON
          : null,
      images: json['images'] != null
          ? List<String>.from(
              jsonDecode(json['images'])) // Parsear la cadena JSON
          : null,
      price_per_match: json['price_per_match'].toString(), // Convertir a String
    );
  }

  @override
  String toString() {
    return 'Field(id: $id, name: $name, description: $description, location: $location, price_per_match: $price_per_match, availableHours: $available_hours, amenities: $amenities, images: $images)';
  }
}
