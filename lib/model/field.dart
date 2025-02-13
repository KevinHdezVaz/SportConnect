import 'dart:convert';

import 'package:flutter/material.dart';

class Field {
  final int id;
  final String name;
  final String description;
  final String municipio;
  final double? latitude;
  final double? longitude;
  final bool is_active;
  final String type;
  final Map<String, List<String>> available_hours;
  final List<String>? amenities;
  final List<String>? images; // Permitir que sea null
  final double price_per_match; // Asegúrate de que sea double

  Field({
    required this.id,
    required this.name,
    required this.description,
    required this.municipio,
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
  debugPrint('\n=== PARSEANDO CAMPO ===');
  debugPrint('JSON recibido: $json');
  
  final lat = json['latitude'];
  final lng = json['longitude'];
  
  debugPrint('Latitude raw: $lat (${lat.runtimeType})');
  debugPrint('Longitude raw: $lng (${lng.runtimeType})');
  
  final parsedLat = double.tryParse(lat.toString());
  final parsedLng = double.tryParse(lng.toString());
  
  debugPrint('Latitude parsed: $parsedLat');
  debugPrint('Longitude parsed: $parsedLng');

   List<String>? imagesList;
  var imagesData = json['images'];
  
  try {
    if (imagesData != null) {
      if (imagesData is String) {
         imagesList = List<String>.from(jsonDecode(imagesData));
      } else if (imagesData is List) {
         imagesList = imagesData.map((e) => e.toString()).toList();
      }
      debugPrint('Lista de imágenes procesada: $imagesList');
    }
  } catch (e) {
    print('Error procesando imágenes: $e');
    imagesList = null;
  }

   Map<String, List<String>> processedHours = {};
  if (json['available_hours'] != null) {
    if (json['available_hours'] is String) {
      processedHours = Map<String, List<String>>.from(
        jsonDecode(json['available_hours']).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        ),
      );
    } else {
      processedHours = Map<String, List<String>>.from(
        json['available_hours'].map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        ),
      );
    }
  }

  List<String>? amenitiesList;
  if (json['amenities'] != null) {
    if (json['amenities'] is String) {
      amenitiesList = List<String>.from(jsonDecode(json['amenities']));
    } else {
      amenitiesList = (json['amenities'] as List).map((e) => e.toString()).toList();
    }
  }
  
  return Field(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    municipio: json['municipio'],
    latitude: parsedLat,
    longitude: parsedLng,
    is_active: json['is_active'],
    type: json['type'],
    available_hours: processedHours,
    amenities: amenitiesList,
    images: imagesList,
      price_per_match: double.parse(json['price_per_match'].toString()), // Convertir a double
  );
}

  @override
  String toString() {
    return 'Field(id: $id, name: $name, description: $description,latitude: $latitude, longitude: $longitude,  municipio: $municipio, price_per_match: $price_per_match, availableHours: $available_hours, amenities: $amenities, images: $images)';
  }
}
 