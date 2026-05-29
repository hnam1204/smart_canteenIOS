import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class UserRepository {
  UserRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<UserModel?> watchUser(String uid) => _service.streamDocument(
    document: _service.collection('users').doc(uid),
    fromFirestore: UserModel.fromFirestore,
  );

  Future<UserModel?> getUser(String uid) => _service.getDocument(
    document: _service.collection('users').doc(uid),
    fromFirestore: UserModel.fromFirestore,
  );

  Future<void> save(UserModel user) => _service.set(
    _service.collection('users').doc(user.uid),
    user.toFirestore(),
    merge: true,
  );

  Future<void> updateProfile(String uid, Map<String, dynamic> data) =>
      _service.set(_service.collection('users').doc(uid), data, merge: true);
}
