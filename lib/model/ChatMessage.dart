class ChatMessage {
  final int id;
  final int userId;
  final String message;
  final String userName;
  final String? userImage;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final DateTime createdAt;
  final ChatMessage? replyTo;  // Mensaje al que se responde

  ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.userName,
    this.userImage,
    this.fileUrl,
    this.fileType,
    this.fileName,
    required this.createdAt,
    this.replyTo,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userId: json['user_id'],
      message: json['mensaje'] ?? '',
      userName: json['user_name'] ?? 'Usuario',
      userImage: json['user_image'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileName: json['file_name'],
      createdAt: DateTime.parse(json['created_at']),
      replyTo: json['reply_to'] != null 
          ? ChatMessage.fromJson(json['reply_to']) 
          : null,
    );
  }
}