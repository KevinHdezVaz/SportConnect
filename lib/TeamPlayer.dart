import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/User.dart';

class TeamPlayer {
  final int id;
  final String position;
  final int equipoPartidoId;
  final User? user;

  TeamPlayer({
    required this.id,
    required this.position,
    required this.equipoPartidoId,
    this.user,
  });

  factory TeamPlayer.fromJson(Map<String, dynamic> json) {
    debugPrint('Parseando TeamPlayer: ${json.toString()}');
    return TeamPlayer(
      id: json['id'] ?? 0,
      position: json['position'] ?? '',
      equipoPartidoId: json['equipo_partido_id'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'equipo_partido_id': equipoPartidoId,
      'user': user != null ? {
        'id': user!.id,
        'name': user!.name,
        'profile_image': user!.profileImage,
      } : null,
    };
  }
  
}