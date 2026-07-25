import '../core/api_client.dart';

class ChatMessageModel {
  final int id;
  final int orderId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String? senderImage;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.senderImage,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    String? photoUrl = json['sender_image'];

    if (photoUrl != null && photoUrl.startsWith('/')) {
      final base = ApiClient.baseUrl.replaceAll('/api/v1/', '');
      photoUrl = "$base$photoUrl";
    }

    return ChatMessageModel(
      id: json['id'],
      orderId: json['order'],
      senderId: json['sender'],
      senderName: json['sender_name'] ?? 'Unknown',
      senderRole: json['sender_role'] ?? 'customer',
      senderImage: photoUrl,
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'sender': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'sender_image': senderImage,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
