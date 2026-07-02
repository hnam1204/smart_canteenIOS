import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/perf_logger.dart';
import '../core/utils/repository_cache.dart';
import '../models/banner_model.dart';

class BannerRepository {
  final FirebaseFirestore? _firestore;

  BannerRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  static CacheEntry<List<BannerModel>>? _cache;
  static Future<List<BannerModel>>? _inFlight;
  static const Duration _ttl = Duration(minutes: 10);

  Stream<List<BannerModel>> watchActiveBanners() async* {
    if (Firebase.apps.isEmpty) {
      yield const <BannerModel>[];
      return;
    }
    final cached = _cache;
    if (cached != null) yield _activeOnly(cached.data);
    yield await loadActiveBanners();
  }

  Future<List<BannerModel>> loadActiveBanners({
    bool forceRefresh = false,
  }) async {
    if (Firebase.apps.isEmpty) return const <BannerModel>[];
    final cached = _cache;
    if (!forceRefresh && cached != null && cached.isValid(_ttl)) {
      return _activeOnly(cached.data);
    }

    final inFlight = _inFlight;
    if (inFlight != null) return _activeOnly(await inFlight);

    final request = _fetchBanners();
    _inFlight = request;
    try {
      return _activeOnly(await request);
    } finally {
      _inFlight = null;
    }
  }

  Future<List<BannerModel>> _fetchBanners() async {
    final banners = await traceAsync('loadBanners', () async {
      try {
        final snapshot = await _db
            .collection('banners')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .limit(20)
            .get();
        return snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList(growable: false);
      } on FirebaseException catch (error) {
        if (!_isMissingIndex(error)) rethrow;
        final snapshot = await _db
            .collection('banners')
            .where('isActive', isEqualTo: true)
            .limit(20)
            .get();
        return snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    });
    _cache = CacheEntry(data: banners, cachedAt: DateTime.now());
    return banners;
  }

  List<BannerModel> _activeOnly(List<BannerModel> banners) {
    final now = DateTime.now();
    return banners
        .where((banner) {
          final isStarted =
              banner.startAt.isBefore(now) ||
              banner.startAt.isAtSameMomentAs(now);
          final isNotExpired =
              banner.endAt.isAfter(now) || banner.endAt.isAtSameMomentAs(now);
          return banner.isActive && isStarted && isNotExpired;
        })
        .toList(growable: false);
  }

  bool _isMissingIndex(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';
    return error.code == 'failed-precondition' || message.contains('index');
  }
}
