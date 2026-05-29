import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class ReviewRepository {
  ReviewRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<List<ReviewModel>> watchReviews(String userId) =>
      _service.streamCollection(
        query: _service
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
        fromFirestore: ReviewModel.fromFirestore,
      );

  Stream<List<ReviewModel>> watchFoodReviews(String foodId) {
    final trimmed = foodId.trim();
    if (trimmed.isEmpty) return Stream<List<ReviewModel>>.value(const []);
    return _service.streamCollection(
      query: _service.collection('reviews').where('foodId', isEqualTo: trimmed),
      fromFirestore: ReviewModel.fromFirestore,
    );
  }

  Future<ReviewModel?> getReviewForOrder(String orderId) async {
    final snapshot = await _service.collection('reviews')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ReviewModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> save(ReviewModel review) => _service.set(
    _service.collection('reviews').doc(review.id),
    review.toFirestore(),
    merge: true,
  );

  Future<Result<void>> submitReview({
    required ReviewModel review,
    required String orderId,
    required String userId,
    int? pointsReward,
  }) async {
    try {
      final firestore = _service.firestore;
      final orderRef = firestore.collection('orders').doc(orderId);
      final reviewRef = firestore.collection('reviews').doc(review.id);
      
      await firestore.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) {
          throw Exception('Đơn hàng không tồn tại.');
        }
        final order = OrderModel.fromFirestore(orderSnap);
        
        if (order.userId != userId) {
          throw Exception('Đơn hàng không thuộc về tài khoản này.');
        }
        if (order.orderStatus != 'delivered' && order.orderStatus != 'completed') {
          throw Exception('Chỉ có thể đánh giá sau khi đơn hàng đã giao.');
        }
        if (order.hasReview) {
          throw Exception('Bạn đã đánh giá đơn hàng này rồi.');
        }

        final reviewSnap = await transaction.get(reviewRef);
        if (reviewSnap.exists) {
          throw Exception('Bạn đã đánh giá đơn hàng này rồi.');
        }
        
        transaction.set(reviewRef, review.toFirestore());
        
        transaction.update(orderRef, {
          'hasReview': true,
          'reviewId': review.id,
          'reviewedAt': Timestamp.now(),
        });
        
        final logRef = firestore.collection('activity_logs').doc();
        transaction.set(logRef, {
          'id': logRef.id,
          'userId': userId,
          'type': 'review',
          'title': 'Đã đánh giá đơn hàng',
          'description': 'Mã đơn hàng: ${order.orderCode}',
          'createdAt': Timestamp.now(),
        });
        
        if (pointsReward != null && pointsReward > 0) {
          final userRef = firestore.collection('users').doc(userId);
          transaction.update(userRef, {
            'points': FieldValue.increment(pointsReward),
          });
          
          final historyRef = firestore.collection('reward_histories').doc();
          transaction.set(historyRef, {
            'id': historyRef.id,
            'userId': userId,
            'type': 'earned',
            'title': 'Đánh giá đơn hàng',
            'points': pointsReward,
            'createdAt': Timestamp.now(),
            'status': 'success',
            'orderId': orderId,
          });
        }
      });
      return Result.success(null);
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in submitReview: $e\n$stack');
      String errMsg = 'Lỗi hệ thống Firestore';
      if (e.code == 'permission-denied') errMsg = 'Không có quyền thực hiện thao tác này.';
      if (e.code == 'not-found') errMsg = 'Tài liệu không tìm thấy.';
      if (e.code == 'already-exists') errMsg = 'Đã tồn tại đánh giá cho đơn hàng này.';
      return Result.failure(errMsg);
    } on Exception catch (e, stack) {
      debugPrint('Exception in submitReview: $e\n$stack');
      return Result.failure(e.toString().replaceAll('Exception: ', ''));
    } catch (e, stack) {
      debugPrint('Error in submitReview: $e\n$stack');
      return Result.failure('Đã xảy ra lỗi không xác định.');
    }
  }
}
