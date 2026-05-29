import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class OrderRepository {
  OrderRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<List<OrderModel>> watchOrders(String userId) =>
      _service.streamCollection(
        query: _service.collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
        fromFirestore: OrderModel.fromFirestore,
      );

  Stream<OrderModel?> watchOrder(String orderId) => _service.streamDocument(
    document: _service.collection('orders').doc(orderId),
    fromFirestore: OrderModel.fromFirestore,
  );

  Stream<OrderModel?> watchOrderByCode(String orderCode) async* {
    final normalized = orderCode.trim();
    if (normalized.isEmpty) {
      yield null;
      return;
    }
    final snapshot = await _service
        .collection('orders')
        .where('orderCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      yield null;
      return;
    }
    final documentId = snapshot.docs.first.id;
    yield* watchOrder(documentId);
  }

  Future<OrderModel?> getOrder(String orderId) => _service.getDocument(
    document: _service.collection('orders').doc(orderId),
    fromFirestore: OrderModel.fromFirestore,
  );

  Future<OrderModel?> getOrderByCode(String orderCode) async {
    final normalized = orderCode.trim();
    if (normalized.isEmpty) return null;
    final snapshot = await _service
        .collection('orders')
        .where('orderCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return OrderModel.fromFirestore(snapshot.docs.first);
  }

  Future<OrderModel?> getOrderByIdOrCode(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final byId = await getOrder(normalized);
    if (byId != null) return byId;
    return getOrderByCode(normalized);
  }

  Future<Result<String>> createOrder(OrderModel order, {String? userVoucherId, int? discountAmount}) async {
    try {
      final firestore = _service.firestore;
      final normalizedId = order.id.trim();
      final doc = normalizedId.isEmpty
          ? firestore.collection('orders').doc()
          : firestore.collection('orders').doc(normalizedId);
      
      final withDocId = OrderModel(
        id: doc.id,
        userId: order.userId,
        orderCode: order.orderCode,
        items: order.items,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        orderStatus: order.orderStatus,
        pickupCounter: order.pickupCounter,
        note: order.note,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        pickupEnabled: order.pickupEnabled,
        qrCodeData: order.qrCodeData,
        pickupToken: order.pickupToken,
      );

      if (userVoucherId != null && userVoucherId.isNotEmpty) {
        await firestore.runTransaction((transaction) async {
          final userVoucherRef = firestore.collection('user_vouchers').doc(userVoucherId);
          final userVoucherSnap = await transaction.get(userVoucherRef);
          if (!userVoucherSnap.exists) {
            throw Exception('Voucher của người dùng không tồn tại.');
          }
          final userVoucher = UserVoucherModel.fromFirestore(userVoucherSnap);
          if (userVoucher.status != 'available') {
            throw Exception('Voucher này đã được sử dụng hoặc hết hạn.');
          }

          final voucherRef = firestore.collection('vouchers').doc(userVoucher.voucherId);

          transaction.update(userVoucherRef, {
            'status': 'used',
            'usedAt': Timestamp.now(),
            'orderId': doc.id,
          });

          transaction.update(voucherRef, {
            'usedCount': FieldValue.increment(1),
          });

          final usageRef = firestore.collection('voucher_usages').doc();
          final usage = VoucherUsageModel(
            id: usageRef.id,
            userId: order.userId,
            voucherId: userVoucher.voucherId,
            userVoucherId: userVoucherId,
            voucherCode: userVoucher.voucherCode,
            orderId: doc.id,
            discountAmount: discountAmount ?? 0,
            usedAt: DateTime.now(),
          );
          transaction.set(usageRef, usage.toFirestore());

          transaction.set(doc, withDocId.toFirestore());
        });
      } else {
        await _service.set(doc, withDocId.toFirestore());
      }

      return Result.success(doc.id);
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in createOrder: $e\n$stack');
      String errMsg = 'Lỗi hệ thống Firestore';
      if (e.code == 'permission-denied') errMsg = 'Không có quyền thực hiện thao tác này.';
      if (e.code == 'not-found') errMsg = 'Tài liệu không tìm thấy.';
      if (e.code == 'already-exists') errMsg = 'Dữ liệu đã tồn tại.';
      return Result.failure(errMsg);
    } on Exception catch (e, stack) {
      debugPrint('Exception in createOrder: $e\n$stack');
      return Result.failure(e.toString().replaceAll('Exception: ', ''));
    } catch (e, stack) {
      debugPrint('Error in createOrder: $e\n$stack');
      return Result.failure('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<void> create(OrderModel order) => createOrder(order).then((_) {});

  Future<void> updateStatus(String id, String status) async {
    await _service.update(
      _service.collection('orders').doc(id),
      {'orderStatus': status, 'updatedAt': DateTime.now()},
    );

    if (status == 'delivered' || status == 'completed') {
      try {
        final order = await getOrder(id);
        if (order != null) {
          final notifyRef = _service.firestore.collection('notifications').doc();
          await notifyRef.set({
            'userId': order.userId,
            'title': 'Đơn hàng #${order.orderCode}',
            'message': 'Cảm ơn bạn đã dùng bữa tại Smart Canteen. Hãy đánh giá món ăn nhé!',
            'type': 'review',
            'referenceId': id,
            'orderCode': order.orderCode,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e, stack) {
        debugPrint('Error creating review notification: $e\n$stack');
      }
    }
  }
}
