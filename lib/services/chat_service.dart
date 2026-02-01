import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==========================================
  // CREATE OR GET CHAT
  // ==========================================

  /// Create a new chat for a booking or get existing one
  Future<String> createOrGetChat({
    required String bookingId,
    required String customerId,
    required String handymanId,
    required String customerName,
    required String handymanName,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Check if chat already exists for this booking AND this user is a participant
      // We must query with a participant ID for security rules to pass
      final existingChat = await _db
          .collection('chats')
          .where('booking_id', isEqualTo: bookingId)
          .where(currentUserId == customerId ? 'customer_id' : 'handyman_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatDoc = await _db.collection('chats').add({
        'booking_id': bookingId,
        'customer_id': customerId,
        'handyman_id': handymanId,
        'customer_name': customerName,
        'handyman_name': handymanName,
        'last_message': 'Chat started',
        'last_message_time': FieldValue.serverTimestamp(),
        'last_message_sender_id': '',
        'unread_count_customer': 0,
        'unread_count_handyman': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return chatDoc.id;
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // SEND MESSAGE
  // ==========================================

  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String senderName,
    required String senderType,
    String messageType = 'text',
    String? imageUrl,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final messageData = {
        'sender_id': currentUserId,
        'sender_name': senderName,
        'sender_type': senderType,
        'message': message,
        'message_type': messageType,
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'read_at': null,
      };

      // Add message to subcollection
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update chat metadata
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();

      if (chatData != null) {
        final isCustomer = senderType == 'customer';

        await _db.collection('chats').doc(chatId).update({
          'last_message': message,
          'last_message_time': FieldValue.serverTimestamp(),
          'last_message_sender_id': currentUserId,
          'updated_at': FieldValue.serverTimestamp(),
          // Increment unread count for the receiver
          isCustomer
              ? 'unread_count_handyman'
              : 'unread_count_customer': FieldValue.increment(1),
        });

        // Send notification to the other party
        final receiverId = isCustomer
            ? chatData['handyman_id']
            : chatData['customer_id'];

        await _sendChatNotification(
          recipientId: receiverId,
          senderName: senderName,
          message: message,
          chatId: chatId,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // GET MESSAGES STREAM
  // ==========================================

  Stream<List<Message>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // ==========================================
  // GET CHAT STREAM
  // ==========================================

  Stream<Chat?> getChat(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Chat.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // ==========================================
  // GET USER CHATS
  // ==========================================

  Stream<List<Chat>> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('customer_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .asyncMap((customerChats) async {
      // Also get chats where user is handyman
      final handymanChatsSnapshot = await _db
          .collection('chats')
          .where('handyman_id', isEqualTo: userId)
          .orderBy('updated_at', descending: true)
          .get();

      final allChats = [
        ...customerChats.docs.map((doc) => Chat.fromFirestore(doc)),
        ...handymanChatsSnapshot.docs.map((doc) => Chat.fromFirestore(doc)),
      ];

      // Sort by updated_at
      allChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return allChats;
    });
  }

  // ==========================================
  // MARK MESSAGES AS READ
  // ==========================================

  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();

      if (chatData == null) return;

      final isCustomer = currentUserId == chatData['customer_id'];

      // Get unread messages from the other user
      final unreadMessages = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      // Batch update all unread messages
      final batch = _db.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'read': true,
          'read_at': FieldValue.serverTimestamp(),
        });
      }

      // Reset unread count for current user
      batch.update(_db.collection('chats').doc(chatId), {
        isCustomer
            ? 'unread_count_customer'
            : 'unread_count_handyman': 0,
      });

      await batch.commit();
    } catch (e) {
      // Silently fail - not critical
      print('Error marking messages as read: $e');
    }
  }

  // ==========================================
  // GET CHAT BY BOOKING ID
  // ==========================================

  Future<String?> getChatIdByBookingId(String bookingId) async {
    if (currentUserId == null) return null;

    try {
      // We must check both potential roles or perform two queries. 
      // Simplest for a single booking: query where user is customer
      final customerSnapshot = await _db
          .collection('chats')
          .where('booking_id', isEqualTo: bookingId)
          .where('customer_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        return customerSnapshot.docs.first.id;
      }

      // If not found, check where user is handyman
      final handymanSnapshot = await _db
          .collection('chats')
          .where('booking_id', isEqualTo: bookingId)
          .where('handyman_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (handymanSnapshot.docs.isNotEmpty) {
        return handymanSnapshot.docs.first.id;
      }
      
      return null;
    } catch (e) {
      print('Error in getChatIdByBookingId: $e');
      return null;
    }
  }

  // ==========================================
  // SEND NOTIFICATION
  // ==========================================

  Future<void> _sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'recipientId': recipientId,
        'title': senderName,
        'message': message.length > 50
            ? '${message.substring(0, 50)}...'
            : message,
        'type': 'message',
        'chatId': chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Silently fail - notification is not critical
      print('Error sending chat notification: $e');
    }
  }

  // ==========================================
  // GET TOTAL UNREAD COUNT
  // ==========================================

  Stream<int> getTotalUnreadCount(String userId) {
    return getUserChats(userId).map((chats) {
      int total = 0;
      for (var chat in chats) {
        total += chat.getUnreadCount(userId);
      }
      return total;
    });
  }
}
