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

  // Procesar imágenes
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

  // Procesar available_hours
  Map<String, List<String>> processedHours = {};
  var availableHours = json['available_hours'];
  try {
    if (availableHours != null) {
      if (availableHours is String) {
        if (availableHours != '[]') {
          var decodedHours = jsonDecode(availableHours);
          if (decodedHours is Map) {
            decodedHours.forEach((key, value) {
              if (value is List) {
                processedHours[key.toString()] = List<String>.from(value);
              }
            });
          }
        }
      } else if (availableHours is Map) {
        availableHours.forEach((key, value) {
          if (value is List) {
            processedHours[key.toString()] = List<String>.from(value);
          }
        });
      }
    }
  } catch (e) {
    print('Error procesando available_hours: $e');
    processedHours = {};
  }

  // Procesar amenities
  List<String>? amenitiesList;
  try {
    var amenities = json['amenities'];
    if (amenities != null) {
      if (amenities is String) {
        amenitiesList = List<String>.from(jsonDecode(amenities));
      } else if (amenities is List) {
        amenitiesList = List<String>.from(amenities);
      }
    }
  } catch (e) {
    print('Error procesando amenities: $e');
    amenitiesList = null;
  }

  return Field(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    municipio: json['municipio'],
    latitude: parsedLat,
    longitude: parsedLng,
    is_active: json['is_active'],
    type: json['type'] ?? 'fut7', // Valor por defecto si no se especifica
    available_hours: processedHours,
    amenities: amenitiesList,
    images: imagesList,
    price_per_match: double.tryParse(json['price_per_match']?.toString() ?? '0') ?? 0.0,
  );
}}