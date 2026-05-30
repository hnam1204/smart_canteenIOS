import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../models/firestore_models.dart' as firestore;
import '../../../repositories/notification_repository.dart';
import 'notification_model.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({NotificationRepository? repository})
    : _repository = repository;

  NotificationRepository? _repository;
  NotificationFilter _filter = NotificationFilter.all;
  List<AppNotification> _notifications = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _disposed = false;
  StreamSubscription<List<firestore.NotificationModel>>? _subscription;

  NotificationFilter get filter => _filter;
  bool get loading => _loading;
  bool get refreshing => _refreshing;

  int get unreadCount =>
      _notifications.where((notification) => notification.isUnread).length;

  List<AppNotification> get visibleNotifications {
    if (_filter == NotificationFilter.all) return _notifications;
    return _notifications
        .where((notification) => notification.filter == _filter)
        .toList(growable: false);
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _repository ??= NotificationRepository();
      await _subscription?.cancel();
      _subscription = _repository!
          .watchNotifications(FirebaseAuth.instance.currentUser!.uid)
          .listen(
            (notifications) {
              if (_disposed) return;
              _notifications = notifications
                  .map(_fromFirestore)
                  .toList(growable: false);
              _loading = false;
              _refreshing = false;
              notifyListeners();
            },
            onError: (_) {
              if (_disposed) return;
              _loading = false;
              _refreshing = false;
              notifyListeners();
            },
          );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (_disposed) return;
    _notifications = List<AppNotification>.of(demoNotifications);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _refreshing = true;
      notifyListeners();
      await load();
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_disposed) return;
    final readIds = _notifications
        .where((notification) => !notification.isUnread)
        .map((notification) => notification.id)
        .toSet();
    _notifications = demoNotifications
        .map(
          (notification) => readIds.contains(notification.id)
              ? notification.copyWith(isUnread: false, isNew: false)
              : notification,
        )
        .toList(growable: false);
    _refreshing = false;
    notifyListeners();
  }

  void setFilter(NotificationFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void markAsRead(String id) {
    var updated = false;
    _notifications = _notifications
        .map((notification) {
          if (notification.id != id || !notification.isUnread) {
            return notification;
          }
          updated = true;
          return notification.copyWith(isUnread: false, isNew: false);
        })
        .toList(growable: false);
    if (updated) notifyListeners();
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      unawaited((_repository ??= NotificationRepository()).markRead(id));
    }
  }

  void markAllAsRead() {
    if (unreadCount == 0) return;
    _notifications = _notifications
        .map(
          (notification) =>
              notification.copyWith(isUnread: false, isNew: false),
        )
        .toList(growable: false);
    notifyListeners();
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      unawaited(
        (_repository ??= NotificationRepository()).markAllRead(
          FirebaseAuth.instance.currentUser!.uid,
        ),
      );
    }
  }

  AppNotification _fromFirestore(firestore.NotificationModel item) {
    final type = switch (item.type) {
      'order' || 'orderCompleted' || 'orderPreparing' => NotificationType.order,
      'payment' => NotificationType.payment,
      'support' => NotificationType.support,
      'voucher' || 'discount' => NotificationType.voucher,
      'reward' || 'points' => NotificationType.reward,
      'review' => NotificationType.review,
      'promotion' => NotificationType.promotion,
      _ => NotificationType.system,
    };
    final difference = DateTime.now().difference(item.createdAt);
    final timeLabel = difference.inHours < 1
        ? '${difference.inMinutes.clamp(1, 59)} phút trước'
        : difference.inDays < 1
        ? '${difference.inHours} giờ trước'
        : '${difference.inDays} ngày trước';
    return AppNotification(
      id: item.id,
      type: type,
      title: item.title,
      message: item.message,
      timeLabel: timeLabel,
      isUnread: !item.isRead,
      isNew: !item.isRead,
      referenceId: item.referenceId,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
