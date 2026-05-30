import 'package:firebase_auth/firebase_auth.dart';

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
  }) {
    return _firebase.signIn(email, password);
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
