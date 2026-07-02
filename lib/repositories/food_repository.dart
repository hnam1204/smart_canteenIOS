import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/perf_logger.dart';
import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class FoodRepository {
  FoodRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;
  static List<FoodModel> _cache = const [];
  static DateTime? _lastSyncAt;
  static Future<List<FoodModel>>? _inFlightSync;
  static const Duration _syncInterval = Duration(minutes: 5);

  List<FoodModel> getCachedFoods() => List<FoodModel>.unmodifiable(_cache);

  bool get hasCache => _cache.isNotEmpty;

  Stream<FoodModel?> watchFood(String foodId) {
    final trimmed = foodId.trim();
    if (trimmed.isEmpty) return Stream<FoodModel?>.value(null);
    return _service.streamDocument(
      document: _service.collection('foods').doc(trimmed),
      fromFirestore: FoodModel.fromFirestore,
    );
  }

  Stream<List<FoodModel>> watchFoods({String? categoryId}) async* {
    if (hasCache) {
      yield _filterByCategory(getCachedFoods(), categoryId);
    }
    final latest = await syncFoods();
    yield _filterByCategory(latest, categoryId);
  }

  Future<List<FoodModel>> loadFoods({bool forceRefresh = false}) async {
    if (!forceRefresh && hasCache) return getCachedFoods();
    return syncFoods(force: forceRefresh);
  }

  Future<List<FoodModel>> syncFoods({bool force = false}) {
    if (!force &&
        _lastSyncAt != null &&
        DateTime.now().difference(_lastSyncAt!) < _syncInterval &&
        hasCache) {
      return Future.value(getCachedFoods());
    }
    final inflight = _inFlightSync;
    if (inflight != null) return inflight;
    final request = _fetchFoods();
    _inFlightSync = request;
    return request.whenComplete(() => _inFlightSync = null);
  }

  Future<List<FoodModel>> _fetchFoods() async {
    final foods = await traceAsync('loadFoods', () async {
      try {
        final query = _service
            .collection('foods')
            .where('isAvailable', isEqualTo: true)
            .orderBy('soldCount', descending: true)
            .limit(50);
        final snapshot = await query.get();
        return snapshot.docs
            .map(FoodModel.fromFirestore)
            .toList(growable: false);
      } on FirebaseException catch (error) {
        if (!_isMissingIndex(error)) rethrow;
        debugPrint('Missing index for foods query, using client sort: $error');
        final fallbackQuery = _service
            .collection('foods')
            .where('isAvailable', isEqualTo: true)
            .limit(50);
        final snapshot = await fallbackQuery.get();
        return snapshot.docs
            .map(FoodModel.fromFirestore)
            .toList(growable: false)
          ..sort(_sortByPopularity);
      }
    });
    _cache = foods;
    _lastSyncAt = DateTime.now();
    return foods;
  }

  int _sortByPopularity(FoodModel left, FoodModel right) {
    final soldCompare = right.soldCount.compareTo(left.soldCount);
    if (soldCompare != 0) return soldCompare;
    return right.rating.compareTo(left.rating);
  }

  bool _isMissingIndex(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';
    return error.code == 'failed-precondition' || message.contains('index');
  }

  List<FoodModel> _filterByCategory(List<FoodModel> foods, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return foods;
    return foods
        .where((food) => food.categoryId == categoryId)
        .toList(growable: false);
  }

  Future<void> save(FoodModel food) => _service.set(
    _service.collection('foods').doc(food.id),
    food.toFirestore(),
  );
}
