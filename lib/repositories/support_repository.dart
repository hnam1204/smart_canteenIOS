import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket_model.dart';
import '../models/support_message_model.dart';

class SupportRepository {
  final FirebaseFirestore? _firestore;

  SupportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<SupportTicketModel>> watchUserTickets(String userId) {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <SupportTicketModel>[]);
    }
    return _db
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  Stream<SupportTicketModel?> watchTicket(String ticketId) {
    if (Firebase.apps.isEmpty) {
      return Stream.value(null);
    }
    return _db
        .collection('support_tickets')
        .doc(ticketId)
        .snapshots()
        .map((doc) => doc.exists ? SupportTicketModel.fromFirestore(doc) : null);
  }

  Stream<List<SupportMessageModel>> watchTicketMessages(String ticketId) {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <SupportMessageModel>[]);
    }
    return _db
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createTicket(SupportTicketModel ticket, String messageText) async {
    final batch = _db.batch();
    
    final ticketRef = _db.collection('support_tickets').doc(ticket.id);
    batch.set(ticketRef, {
      ...ticket.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    
    final messageRef = ticketRef.collection('messages').doc();
    final firstMessage = SupportMessageModel(
      id: messageRef.id,
      ticketId: ticket.id,
      senderId: ticket.userId,
      senderName: ticket.fullName,
      senderRole: 'user',
      message: messageText,
      imageUrls: ticket.imageUrls,
      isRead: true, // Sent by user, so user has read it
      createdAt: ticket.createdAt,
    );
    batch.set(messageRef, {
      ...firstMessage.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final logRef = _db.collection('activity_logs').doc();
    batch.set(logRef, {
      'id': logRef.id,
      'userId': ticket.userId,
      'type': 'support',
      'title': 'Đã tạo yêu cầu hỗ trợ',
      'description': 'Mã yêu cầu: ${ticket.id}',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String messageText,
    List<String> imageUrls = const [],
  }) async {
    final ticketRef = _db.collection('support_tickets').doc(ticketId);
    
    await _db.runTransaction((transaction) async {
      final ticketSnap = await transaction.get(ticketRef);
      if (!ticketSnap.exists) {
        throw Exception('Yêu cầu hỗ trợ không tồn tại.');
      }
      final ticket = SupportTicketModel.fromFirestore(ticketSnap);
      if (ticket.status == 'closed') {
        throw Exception('Yêu cầu hỗ trợ đã đóng, không thể gửi tin nhắn.');
      }
      
      final messageRef = ticketRef.collection('messages').doc();
      
      transaction.set(messageRef, {
        'id': messageRef.id,
        'ticketId': ticketId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': 'user',
        'message': messageText,
        'imageUrls': imageUrls,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      transaction.update(ticketRef, {
        'lastMessage': messageText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByAdmin': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    });
  }

  Future<void> markTicketAsRead(String ticketId) async {
    final ticketRef = _db.collection('support_tickets').doc(ticketId);
    
    // Update ticket document unread status
    await ticketRef.update({'unreadByUser': false});
    
    // Find and update all unread messages from admin to isRead = true
    final unreadMessages = await ticketRef
        .collection('messages')
        .where('senderRole', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .get();
        
    if (unreadMessages.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }
}
