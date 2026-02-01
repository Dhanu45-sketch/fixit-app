import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String bookingId;
  final String customerId;
  final String handymanId;
  final String customerName;
  final String handymanName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCountCustomer;
  final int unreadCountHandyman;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.handymanId,
    required this.customerName,
    required this.handymanName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCountCustomer = 0,
    this.unreadCountHandyman = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      bookingId: data['booking_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      handymanId: data['handyman_id'] ?? '',
      customerName: data['customer_name'] ?? 'Customer',
      handymanName: data['handyman_name'] ?? 'Handyman',
      lastMessage: data['last_message'] ?? '',
      lastMessageTime: (data['last_message_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['last_message_sender_id'] ?? '',
      unreadCountCustomer: data['unread_count_customer'] ?? 0,
      unreadCountHandyman: data['unread_count_handyman'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'handyman_id': handymanId,
      'customer_name': customerName,
      'handyman_name': handymanName,
      'last_message': lastMessage,
      'last_message_time': Timestamp.fromDate(lastMessageTime),
      'last_message_sender_id': lastMessageSenderId,
      'unread_count_customer': unreadCountCustomer,
      'unread_count_handyman': unreadCountHandyman,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper to get unread count for current user
  int getUnreadCount(String userId) {
    if (userId == customerId) {
      return unreadCountCustomer;
    } else if (userId == handymanId) {
      return unreadCountHandyman;
    }
    return 0;
  }

  // Helper to get other participant's name
  String getOtherParticipantName(String userId) {
    if (userId == customerId) {
      return handymanName;
    } else {
      return customerName;
    }
  }

  // Helper to get other participant's ID
  String getOtherParticipantId(String userId) {
    if (userId == customerId) {
      return handymanId;
    } else {
      return customerId;
    }
  }
}