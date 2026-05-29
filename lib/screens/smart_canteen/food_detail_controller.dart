import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/firestore_models.dart' as store;
import '../../repositories/food_repository.dart';
import '../../repositories/review_repository.dart';

class FoodDetailController extends ChangeNotifier {
  FoodDetailController({
    required this.foodId,
    FoodRepository? foodRepository,
    ReviewRepository? reviewRepository,
  }) : _foodRepository = foodRepository,
       _reviewRepository = reviewRepository;

  final String foodId;
  FoodRepository? _foodRepository;
  ReviewRepository? _reviewRepository;
  StreamSubscription<store.FoodModel?>? _foodSubscription;
  StreamSubscription<List<store.ReviewModel>>? _reviewSubscription;
  store.FoodModel? _food;
  List<store.ReviewModel> _reviews = const [];
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  store.FoodModel? get food => _food;
  List<store.ReviewModel> get reviews => List.unmodifiable(_reviews);
  bool get loading => _loading;
  String? get error => _error;
  int get reviewCount => _reviews.length;

  double get averageRating {
    if (_reviews.isEmpty) return _food?.rating ?? 0;
    final total = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / _reviews.length;
  }

  Future<void> bind() async {
    if (Firebase.apps.isEmpty || foodId.trim().isEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();

    _foodRepository ??= FoodRepository();
    _reviewRepository ??= ReviewRepository();
    await _foodSubscription?.cancel();
    await _reviewSubscription?.cancel();

    _foodSubscription = _foodRepository!
        .watchFood(foodId)
        .listen(
          (food) {
            if (_disposed) return;
            _food = food;
            _loading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (_disposed) return;
            debugPrint('Food detail load error: $error');
            _loading = false;
            _error = 'Không thể tải thông tin món ăn.';
            notifyListeners();
          },
        );

    _reviewSubscription = _reviewRepository!
        .watchFoodReviews(foodId)
        .listen(
          (reviews) {
            if (_disposed) return;
            _reviews = reviews;
            notifyListeners();
          },
          onError: (Object error) {
            if (_disposed) return;
            debugPrint('Food reviews load error: $error');
            _reviews = const [];
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_foodSubscription?.cancel());
    unawaited(_reviewSubscription?.cancel());
    super.dispose();
  }
}
