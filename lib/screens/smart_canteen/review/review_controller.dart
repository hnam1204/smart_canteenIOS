import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../../../models/firestore_models.dart' as store;
import '../../../repositories/review_repository.dart';
import 'review_model.dart';

class ReviewController extends SafeChangeNotifier {
  ReviewController({this.order = demoReviewOrder, ReviewRepository? repository})
    : _repository = repository,
      _history = List<ReviewModel>.of(demoReviewHistory),
      _serviceRatings = {
        for (final service in demoServiceRatings) service.id: 0,
      } {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      _repository ??= ReviewRepository();
      _history.clear();
      _subscription = _repository!
          .watchReviews(FirebaseAuth.instance.currentUser!.uid)
          .listen((items) {
            _history
              ..clear()
              ..addAll(items.map(_fromFirestore));
            notifyListeners();
          });
    }
  }

  final ReviewOrderModel order;
  ReviewRepository? _repository;
  final List<ReviewModel> _history;
  final Map<String, int> _serviceRatings;
  final Set<String> _selectedTags = {};
  final List<ReviewImageModel> _images = [];

  int _rating = 0;
  String _comment = '';
  bool _submitting = false;
  StreamSubscription<List<store.ReviewModel>>? _subscription;

  int get rating => _rating;
  String get comment => _comment;
  bool get submitting => _submitting;
  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);
  Map<String, int> get serviceRatings => Map.unmodifiable(_serviceRatings);
  List<ReviewImageModel> get images => List.unmodifiable(_images);
  List<ReviewModel> get history => List.unmodifiable(_history);
  bool get canSubmit => _rating > 0 && !_submitting;

  String get ratingLabel {
    switch (_rating) {
      case 1:
        return 'Rất không hài lòng';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Tuyệt vời';
      default:
        return 'Chạm vào sao để đánh giá';
    }
  }

  void setRating(int value) {
    _rating = value;
    notifyListeners();
  }

  void toggleTag(String id) {
    if (!_selectedTags.add(id)) {
      _selectedTags.remove(id);
    }
    notifyListeners();
  }

  void updateComment(String value) {
    _comment = value;
  }

  void setServiceRating(String id, int rating) {
    _serviceRatings[id] = rating;
    notifyListeners();
  }

  void addImage() {
    if (_images.length >= demoReviewImages.length) return;
    _images.add(demoReviewImages[_images.length]);
    notifyListeners();
  }

  void removeImage(String id) {
    _images.removeWhere((image) => image.id == id);
    notifyListeners();
  }

  String? validate() {
    if (_rating == 0) return 'Vui lòng chọn số sao đánh giá.';
    if (_rating < 3 && _comment.trim().isEmpty) {
      return 'Vui lòng chia sẻ lý do khi đánh giá dưới 3 sao.';
    }
    return null;
  }

  Future<Result<ReviewModel>> submit() async {
    final review = ReviewModel(
      orderId: order.id,
      rating: _rating,
      tags: Set<String>.of(_selectedTags),
      comment: _comment.trim(),
      serviceRatings: Map<String, int>.of(_serviceRatings),
      imageCount: _images.length,
      createdAt: 'Vừa xong',
      canEdit: false,
    );
    _submitting = true;
    notifyListeners();
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user != null) {
      final storeReview = store.ReviewModel(
        id: '${user.uid}_${order.id}',
        userId: user.uid,
        orderId: order.id,
        rating: _rating,
        comment: _comment.trim(),
        tags: _selectedTags.toList(growable: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
        userName: user.displayName ?? user.email ?? '',
        foodId: order.items.isEmpty ? '' : order.items.first.name,
        foodName: order.items.isEmpty ? '' : order.items.first.name,
        orderCode: order.id,
        foodIds: const [],
        serviceRatings: Map<String, int>.of(_serviceRatings),
        imageUrls: _images.map((img) => img.id).toList(),
      );
      final repoResult = await (_repository ??= ReviewRepository())
          .submitReview(
            review: storeReview,
            orderId: order.id,
            userId: user.uid,
            pointsReward: 50,
          );
      if (!repoResult.isSuccess) {
        _submitting = false;
        notifyListeners();
        return Result.failure(
          repoResult.error ?? 'Đã xảy ra lỗi khi gửi đánh giá.',
        );
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
    _history.removeWhere((item) => item.orderId == review.orderId);
    _history.insert(0, review);
    _submitting = false;
    notifyListeners();
    return Result.success(review);
  }

  void editReview(ReviewModel review) {
    // Disabled / No-op as editing is not allowed
  }

  ReviewModel _fromFirestore(store.ReviewModel review) {
    String two(int value) => value.toString().padLeft(2, '0');
    final date = review.createdAt;
    return ReviewModel(
      orderId: review.orderId,
      rating: review.rating,
      tags: review.tags.toSet(),
      comment: review.comment,
      serviceRatings: const {},
      imageCount: 0,
      createdAt:
          '${two(date.day)}/${two(date.month)}/${date.year} - ${two(date.hour)}:${two(date.minute)}',
      canEdit: false,
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
