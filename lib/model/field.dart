import 'dart:convert';

class Field {
  final int id;
  final String name;
  final String description;
  final String location;
  final double pricePerHour;
  final List<String> availableHours;
  final List<String>? amenities;
  final List<String>? images;

  Field({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.pricePerHour,
    required this.availableHours,
    this.amenities,
    this.images,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      pricePerHour: double.parse(json['price_per_hour'].toString()),
      availableHours: List<String>.from(json['available_hours']),
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      images: json['images'] != null
          ? List<String>.from(jsonDecode(json['images']))
          : null,
    );
  }
  // Sobrescribir toString para una representación más legible
  @override
  String toString() {
    return 'Field(id: $id, name: $name, description: $description, location: $location, pricePerHour: $pricePerHour, availableHours: $availableHours, amenities: $amenities, images: $images)';
  }
}
