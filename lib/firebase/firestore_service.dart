import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreException implements Exception {
  const FirestoreException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    final existing = _firestore;
    if (existing != null) return existing;
    if (Firebase.apps.isEmpty) {
      throw const FirestoreException(
        'Firebase chưa được khởi tạo. Vui lòng kiểm tra cấu hình Firebase.',
      );
    }
    return _firestore = FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      firestore.collection(path);

  Stream<List<T>> streamCollection<T>({
    required Query<Map<String, dynamic>> query,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) {
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(fromFirestore).toList(growable: false),
    );
  }

  Stream<T?> streamDocument<T>({
    required DocumentReference<Map<String, dynamic>> document,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) {
    return document.snapshots().map(
      (snapshot) => snapshot.exists ? fromFirestore(snapshot) : null,
    );
  }

  Future<T?> getDocument<T>({
    required DocumentReference<Map<String, dynamic>> document,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) async {
    try {
      final snapshot = await document.get();
      return snapshot.exists ? fromFirestore(snapshot) : null;
    } on FirebaseException catch (error) {
      throw FirestoreException(
        error.message ?? 'Không thể đọc dữ liệu.',
        error,
      );
    }
  }

  Future<void> set(
    DocumentReference<Map<String, dynamic>> document,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await document.set(data, SetOptions(merge: merge));
    } on FirebaseException catch (error) {
      throw FirestoreException(
        error.message ?? 'Không thể lưu dữ liệu.',
        error,
      );
    }
  }

  Future<void> update(
    DocumentReference<Map<String, dynamic>> document,
    Map<String, dynamic> data,
  ) async {
    try {
      await document.update(data);
    } on FirebaseException catch (error) {
      throw FirestoreException(
        error.message ?? 'Không thể cập nhật dữ liệu.',
        error,
      );
    }
  }

  Future<void> delete(DocumentReference<Map<String, dynamic>> document) async {
    try {
      await document.delete();
    } on FirebaseException catch (error) {
      throw FirestoreException(
        error.message ?? 'Không thể xóa dữ liệu.',
        error,
      );
    }
  }

  WriteBatch batch() => firestore.batch();
}
