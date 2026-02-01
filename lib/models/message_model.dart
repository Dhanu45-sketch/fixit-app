import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType; // "customer" or "handyman"
  final String message;
  final String messageType; // "text", "image"
  final String? imageUrl;
  final DateTime timestamp;
  final bool read;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    this.messageType = 'text',
    this.imageUrl,
    required this.timestamp,
    this.read = false,
    this.readAt,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? 'User',
      senderType: data['sender_type'] ?? 'customer',
      message: data['message'] ?? '',
      messageType: data['message_type'] ?? 'text',
      imageUrl: data['image_url'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      readAt: (data['read_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'message': message,
      'message_type': messageType,
      'image_url': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'read_at': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Helper to check if message is sent by current user
  bool isSentByUser(String userId) {
    return senderId == userId;
  }

  // Helper to get formatted time
  String getFormattedTime() {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Helper to get read status icon
  String getReadStatusIcon() {
    if (read) {
      return '✓✓'; // Double check for read
    }
    return '✓'; // Single check for delivered
  }
}