import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_service.dart';
import 'notification_service.dart' as push;
import 'session_manager.dart';

class AuthService {
  AuthService({FirebaseService? firebase, SessionManager? sessions})
    : _firebase = firebase ?? FirebaseService(),
      _sessions = sessions ?? SessionManager();

  final FirebaseService _firebase;
  final SessionManager _sessions;

  Stream<User?> get authStateChanges => _firebase.authStateChanges;

  User? get currentUser => _firebase.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebase.signIn(email, password);
    try {
      final user = credential.user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        String? deviceId = prefs.getString('device_id');
        if (deviceId == null) {
          final random = Random.secure();
          final parts = List<String>.generate(4, (_) => random.nextInt(1000000).toString().padLeft(6, '0'));
          deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${parts.join('')}';
          await prefs.setString('device_id', deviceId);
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('login_sessions')
            .doc(deviceId)
            .set({
          'deviceName': 'iPhone',
          'platform': 'iOS',
          'ipAddress': '192.168.1.10',
          'location': 'Hồ Chí Minh, Việt Nam',
          'loginAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
          'isCurrentDevice': true,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Don't let session logging block sign in
      debugPrint('Error recording login session: $e');
    }
    return credential;
  }

  Future<String?> firebaseIdToken({bool forceRefresh = false}) async {
    final user = _firebase.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  Future<void> saveBackendSession(SessionTokens tokens) =>
      _sessions.save(tokens);

  Future<String?> backendAccessToken({RefreshSession? refresh}) =>
      _sessions.validAccessToken(refresh: refresh);

  Future<void> signOut() async {
    try {
      await push.NotificationService.instance.removeTokenFromFirestore();
    } catch (_) {
      // Token cleanup must never block sign-out.
    }
    await Future.wait([_sessions.clear(), _firebase.signOut()]);
  }
}
