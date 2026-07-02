import '../core/utils/perf_logger.dart';
import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class CategoryRepository {
  CategoryRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;
  static List<CategoryModel> _cache = const [];
  static DateTime? _lastSyncAt;
  static Future<List<CategoryModel>>? _inFlightSync;
  static const Duration _syncInterval = Duration(minutes: 10);

  List<CategoryModel> getCachedCategories() =>
      List<CategoryModel>.unmodifiable(_cache);

  bool get hasCache => _cache.isNotEmpty;

  Stream<List<CategoryModel>> watchCategories() async* {
    if (hasCache) yield getCachedCategories();
    yield await syncCategories();
  }

  Future<List<CategoryModel>> loadCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCache) return getCachedCategories();
    return syncCategories(force: forceRefresh);
  }

  Future<List<CategoryModel>> syncCategories({bool force = false}) {
    if (!force &&
        _lastSyncAt != null &&
        DateTime.now().difference(_lastSyncAt!) < _syncInterval &&
        hasCache) {
      return Future.value(getCachedCategories());
    }
    final inflight = _inFlightSync;
    if (inflight != null) return inflight;
    final request = _fetchCategories();
    _inFlightSync = request;
    return request.whenComplete(() => _inFlightSync = null);
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final categories = await traceAsync('loadCategories', () async {
      final snapshot = await _service
          .collection('categories')
          .orderBy('sortOrder')
          .get();
      return snapshot.docs
          .map(CategoryModel.fromFirestore)
          .toList(growable: false);
    });
    _cache = categories;
    _lastSyncAt = DateTime.now();
    return categories;
  }

  Future<void> save(CategoryModel category) => _service.set(
    _service.collection('categories').doc(category.id),
    category.toFirestore(),
  );
}
