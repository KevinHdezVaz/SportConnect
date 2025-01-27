import 'dart:convert';

class Field {
  final int id;
  final String name;
  final String description;
  final String location;
  final String price_per_hour;
  final int duration_per_match;
  final double? latitude;
  final double? longitude;
  final bool is_active;
  final String type;
  final List<String> available_hours;
  final List<String>? amenities;
  final List<String>? images;
  final String price_per_match;

  Field({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.price_per_hour,
    required this.duration_per_match,
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
      price_per_hour: json['price_per_hour'],
      duration_per_match: json['duration_per_match'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      is_active: json['is_active'],
      type: json['type'],
      available_hours: List<String>.from(json['available_hours']),
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      price_per_match: json['price_per_match'],
    );
  }

  // Sobrescribir toString para una representación más legible
  @override
  String toString() {
    return 'Field(id: $id, name: $name, description: $description, location: $location, price_per_match: $price_per_match, availableHours: $available_hours, amenities: $amenities, images: $images)';
  }
}
