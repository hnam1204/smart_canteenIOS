import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firestore_service.dart';

class RewardHistoryFirestoreModel {
  RewardHistoryFirestoreModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.points,
    required this.createdAt,
    required this.status,
    this.orderId,
  });

  final String id;
  final String userId;
  final String type; // 'earn', 'redeem', 'expired'
  final String title;
  final int points;
  final DateTime createdAt;
  final String status;
  final String? orderId;

  factory RewardHistoryFirestoreModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    debugPrint('Reward History Raw: ${doc.data()}');
    final data = doc.data() ?? const {};
    final rawType = (data['type'] ?? data['action'] ?? 'earn').toString();

    final normalizedType = switch (rawType) {
      'deduct' => 'redeem',
      'add' => 'earn',
      'redeem' => 'redeem',
      'earn' => 'earn',
      'expire' => 'expire',
      'bonus' => 'bonus',
      _ => 'earn',
    };

    final title = (data['title'] ?? data['reason'] ?? data['description'] ?? '').toString();

    return RewardHistoryFirestoreModel(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      type: normalizedType,
      title: title,
      points: (data['points'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'success',
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'type': type,
    'action': type == 'redeem' ? 'deduct' : 'add',
    'title': title,
    'reason': title,
    'points': points,
    'createdAt': Timestamp.fromDate(createdAt),
    'status': status,
    if (orderId != null) 'orderId': orderId,
  };
}

class RewardRepository {
  RewardRepository({FirestoreService? service})
      : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<List<RewardHistoryFirestoreModel>> watchHistory(String userId) {
    try {
      return _service.streamCollection(
        query: _service.collection('reward_histories')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
        fromFirestore: RewardHistoryFirestoreModel.fromFirestore,
      ).handleError((Object error) {
        debugPrint('Reward Error: $error');
        throw error;
      });
    } catch (e, st) {
      debugPrint('Reward Error: $e');
      final cleaned = StackTrace.fromString(
        st.toString().split('\n').where((l) => !l.contains('asynchronous gap')).join('\n')
      );
      debugPrintStack(stackTrace: cleaned);
      rethrow;
    }
  }
}
