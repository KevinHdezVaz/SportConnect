class Story {
  final int id;
  final String title;
  final String imageUrl;
  final String? videoUrl;
  final bool isActive;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.videoUrl,
    required this.isActive,
    required this.expiresAt,
  });

  factory Story.fromJson(Map<String, dynamic> json, String baseUrl) {
    return Story(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'], // Ya no necesita concatenar baseUrl
      videoUrl: json['video_url'],
      isActive: json['is_active'] ?? true,
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}
