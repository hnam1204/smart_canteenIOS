import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class NotificationRepository {
  NotificationRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<List<NotificationModel>> watchNotifications(String userId) =>
      _service.streamCollection(
        query: _service
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
        fromFirestore: NotificationModel.fromFirestore,
      );

  Stream<int> watchUnreadCount(String userId) => _service
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  Future<void> markRead(String id) => _service.update(
    _service.collection('notifications').doc(id),
    {'isRead': true},
  );

  Future<void> markAllRead(String userId) async {
    final snapshot = await _service
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _service.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
