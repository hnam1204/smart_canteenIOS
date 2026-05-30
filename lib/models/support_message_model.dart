import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessageModel {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole; // user | admin
  final String message;
  final List<String> imageUrls;
  final bool isRead;
  final DateTime createdAt;

  SupportMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.imageUrls,
    required this.isRead,
    required this.createdAt,
  });

  factory SupportMessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return SupportMessageModel(
      id: data['id']?.toString() ?? doc.id,
      ticketId: data['ticketId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      senderRole: data['senderRole']?.toString() ?? 'user',
      message: data['message']?.toString() ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isRead: data['isRead'] == true,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'imageUrls': imageUrls,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
