class Story {
  final int id;
  final String imageUrl;
  final String title;
  final DateTime createdAt;
  final String? videoUrl;

  Story({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.createdAt,
    this.videoUrl,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      imageUrl: json['image_url'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      videoUrl: json['video_url'],
    );
  }
}