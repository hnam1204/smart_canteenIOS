import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase chưa được khởi tạo.');
    }
    return _auth ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get firestore {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase chưa được khởi tạo.');
    }
    return _firestore ??= FirebaseFirestore.instance;
  }

  Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerStudent({
    required String fullName,
    required String email,
    required String studentId,
    required String phone,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Không thể tạo tài khoản.');
    }

    try {
      await user.updateDisplayName(fullName);
      final avatarUrl =
          'https://api.dicebear.com/9.x/personas/svg?seed=${user.uid}';
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName,
        'email': email,
        'studentId': studentId,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'points': 0,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      try {
        await user.delete();
      } catch (_) {
        // Preserve the original profile persistence error for the UI.
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await auth.signOut();
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  User? get currentUser => auth.currentUser;

  Stream<User?> get authStateChanges => auth.authStateChanges();
}
