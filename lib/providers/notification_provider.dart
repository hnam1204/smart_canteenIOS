import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationRepository? repository})
    : _repository = repository;

  NotificationRepository? _repository;
  StreamSubscription<int>? _subscription;
  String? _userId;
  int _unreadCount = 0;
  String? _error;

  int get unreadCount => _unreadCount;
  String? get error => _error;

  Future<void> bindCurrentUser() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (_userId == user.uid && _subscription != null)) return;
    _userId = user.uid;
    await _subscription?.cancel();
    _repository ??= NotificationRepository();
    _subscription = _repository!
        .watchUnreadCount(user.uid)
        .listen(
          (count) {
            _unreadCount = count;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> markRead(String notificationId) async {
    await (_repository ??= NotificationRepository()).markRead(notificationId);
  }

  Future<void> markAllRead() async {
    final userId = _userId;
    if (userId == null) return;
    await (_repository ??= NotificationRepository()).markAllRead(userId);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
