import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

class BannerRepository {
  final FirebaseFirestore? _firestore;

  BannerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<BannerModel>> watchActiveBanners() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const <BannerModel>[]);
    }
    return _db
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final banners = snapshot.docs
              .map((doc) => BannerModel.fromFirestore(doc))
              .where((b) {
                // Client-side filtering for startAt <= now and endAt >= now
                final isStarted = b.startAt.isBefore(now) || b.startAt.isAtSameMomentAs(now);
                final isNotExpired = b.endAt.isAfter(now) || b.endAt.isAtSameMomentAs(now);
                return isStarted && isNotExpired;
              })
              .toList();
          
          return banners;
        });
  }
}
