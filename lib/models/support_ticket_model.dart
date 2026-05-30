import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String category;
  final String title;
  final String message;
  final List<String> imageUrls;
  final String status; // pending | replied | closed
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastReply;
  final DateTime? lastReplyAt;
  final bool unreadByUser;
  final bool unreadByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.category,
    required this.title,
    required this.message,
    required this.imageUrls,
    required this.status,
    required this.lastMessage,
    required this.lastMessageAt,
    this.lastReply = '',
    this.lastReplyAt,
    required this.unreadByUser,
    required this.unreadByAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }
    
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SupportTicketModel(
      id: data['id']?.toString() ?? doc.id,
      userId: data['userId']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Khác',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status']?.toString() ?? 'pending',
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageAt: parseDate(data['lastMessageAt']),
      lastReply: data['lastReply']?.toString() ?? '',
      lastReplyAt: parseNullableDate(data['lastReplyAt']),
      unreadByUser: data['unreadByUser'] == true,
      unreadByAdmin: data['unreadByAdmin'] == true,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'category': category,
      'title': title,
      'message': message,
      'imageUrls': imageUrls,
      'status': status,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastReply': lastReply,
      if (lastReplyAt != null) 'lastReplyAt': Timestamp.fromDate(lastReplyAt!),
      'unreadByUser': unreadByUser,
      'unreadByAdmin': unreadByAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SupportTicketModel copyWith({
    String? status,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastReply,
    DateTime? lastReplyAt,
    bool? unreadByUser,
    bool? unreadByAdmin,
    DateTime? updatedAt,
  }) {
    return SupportTicketModel(
      id: id,
      userId: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      category: category,
      title: title,
      message: message,
      imageUrls: imageUrls,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastReply: lastReply ?? this.lastReply,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      unreadByUser: unreadByUser ?? this.unreadByUser,
      unreadByAdmin: unreadByAdmin ?? this.unreadByAdmin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
