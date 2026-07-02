import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/perf_logger.dart';
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
            .orderBy('createdAt', descending: true)
            .limit(30),
        fromFirestore: NotificationModel.fromFirestore,
      );

  Stream<List<NotificationModel>> watchNotificationsPaged(
    String userId,
    int limit,
  ) => _service.streamCollection(
    query: _service
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 30)),
    fromFirestore: NotificationModel.fromFirestore,
  );

  Future<void> deleteNotification(String id) =>
      _service.update(_service.collection('notifications').doc(id), {
        'isRead': true,
        'status': 'deleted',
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<int> watchUnreadCount(String userId) => _service
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  Future<void> markRead(String id) =>
      _service.update(_service.collection('notifications').doc(id), {
        'isRead': true,
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> markAllRead(String userId) async {
    final snapshot = await traceAsync('loadNotifications.unread', () {
      return _service
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get();
    });
    final batch = _service.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'isRead': true,
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
