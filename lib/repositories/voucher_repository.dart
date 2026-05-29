import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart' as store;

class VoucherRepository {
  VoucherRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<List<store.VoucherModel>> watchVouchers() => _service.streamCollection(
    query: _service.collection('vouchers').orderBy('expiredAt'),
    fromFirestore: store.VoucherModel.fromFirestore,
  );

  Stream<List<store.UserVoucherModel>> watchUserVouchers(String userId) => _service.streamCollection(
    query: _service.collection('user_vouchers')
        .where('userId', isEqualTo: userId)
        .orderBy('expiredAt'),
    fromFirestore: store.UserVoucherModel.fromFirestore,
  );

  Future<store.VoucherModel?> getById(String id) => _service.getDocument(
    document: _service.collection('vouchers').doc(id),
    fromFirestore: store.VoucherModel.fromFirestore,
  );

  Future<void> save(store.VoucherModel voucher) => _service.set(
    _service.collection('vouchers').doc(voucher.id),
    voucher.toFirestore(),
  );

  Future<Result<void>> claimVoucher(String userId, String voucherId) async {
    try {
      final firestore = _service.firestore;
      final voucherRef = firestore.collection('vouchers').doc(voucherId);
      final userVoucherRef = firestore.collection('user_vouchers').doc('${userId}_$voucherId');

      await firestore.runTransaction((transaction) async {
        final voucherSnap = await transaction.get(voucherRef);
        if (!voucherSnap.exists) {
          throw Exception('Voucher không tồn tại.');
        }
        final voucher = store.VoucherModel.fromFirestore(voucherSnap);

        if (!voucher.isActive) {
          throw Exception('Voucher không còn hoạt động.');
        }
        if (voucher.expiredAt.isBefore(DateTime.now())) {
          throw Exception('Voucher đã hết hạn.');
        }
        if (voucher.claimedCount >= voucher.claimLimit) {
          throw Exception('Voucher đã hết lượt nhận.');
        }

        final userVoucherSnap = await transaction.get(userVoucherRef);
        if (userVoucherSnap.exists) {
          throw Exception('Bạn đã nhận voucher này rồi.');
        }

        final userVoucher = store.UserVoucherModel(
          id: '${userId}_$voucherId',
          userId: userId,
          voucherId: voucher.id,
          voucherCode: voucher.code,
          title: voucher.title,
          description: voucher.description,
          discountType: voucher.discountType,
          discountValue: voucher.discountValue,
          minOrderAmount: voucher.minOrderAmount,
          maxDiscount: voucher.maxDiscount,
          source: 'claim',
          status: 'available',
          claimedAt: DateTime.now(),
          expiredAt: voucher.expiredAt,
        );

        transaction.set(userVoucherRef, userVoucher.toFirestore());
        transaction.update(voucherRef, {
          'claimedCount': FieldValue.increment(1),
        });
      });
      return Result.success(null);
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in claimVoucher: $e\n$stack');
      String errMsg = 'Lỗi hệ thống Firestore';
      if (e.code == 'permission-denied') errMsg = 'Không có quyền thực hiện thao tác này.';
      if (e.code == 'not-found') errMsg = 'Tài liệu không tìm thấy.';
      if (e.code == 'already-exists') errMsg = 'Dữ liệu đã tồn tại.';
      return Result.failure(errMsg);
    } on Exception catch (e, stack) {
      debugPrint('Exception in claimVoucher: $e\n$stack');
      return Result.failure(e.toString().replaceAll('Exception: ', ''));
    } catch (e, stack) {
      debugPrint('Error in claimVoucher: $e\n$stack');
      return Result.failure('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<Result<void>> exchangeVoucher(String userId, String voucherId) async {
    try {
      final firestore = _service.firestore;
      final voucherRef = firestore.collection('vouchers').doc(voucherId);
      final userVoucherRef = firestore.collection('user_vouchers').doc('${userId}_$voucherId');
      final userRef = firestore.collection('users').doc(userId);

      await firestore.runTransaction((transaction) async {
        final voucherSnap = await transaction.get(voucherRef);
        if (!voucherSnap.exists) {
          throw Exception('Voucher không tồn tại.');
        }
        final voucher = store.VoucherModel.fromFirestore(voucherSnap);

        if (!voucher.isExchangeable || !voucher.isActive) {
          throw Exception('Voucher này không thể quy đổi.');
        }
        if (voucher.expiredAt.isBefore(DateTime.now())) {
          throw Exception('Voucher đã hết hạn.');
        }
        if (voucher.claimedCount >= voucher.claimLimit) {
          throw Exception('Voucher đã hết lượt đổi.');
        }

        final userVoucherSnap = await transaction.get(userVoucherRef);
        if (userVoucherSnap.exists && voucher.userLimit <= 1) {
          throw Exception('Bạn đã sở hữu voucher này rồi.');
        }

        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw Exception('Người dùng không tồn tại.');
        }
        final user = store.UserModel.fromFirestore(userSnap);

        if (user.points < voucher.exchangePoints) {
          throw Exception('Bạn không đủ điểm để đổi voucher này.');
        }

        final userVoucherId = voucher.userLimit <= 1 
            ? '${userId}_$voucherId' 
            : '${userId}_${voucherId}_${DateTime.now().millisecondsSinceEpoch}';

        final userVoucherRefFinal = firestore.collection('user_vouchers').doc(userVoucherId);

        final userVoucher = store.UserVoucherModel(
          id: userVoucherId,
          userId: userId,
          voucherId: voucher.id,
          voucherCode: voucher.code,
          title: voucher.title,
          description: voucher.description,
          discountType: voucher.discountType,
          discountValue: voucher.discountValue,
          minOrderAmount: voucher.minOrderAmount,
          maxDiscount: voucher.maxDiscount,
          source: 'exchange_points',
          status: 'available',
          claimedAt: DateTime.now(),
          expiredAt: voucher.expiredAt,
        );

        final historyRef = firestore.collection('reward_histories').doc();
        final historyData = {
          'id': historyRef.id,
          'userId': userId,
          'type': 'redeem',
          'title': 'Đổi ${voucher.title}',
          'points': -voucher.exchangePoints,
          'createdAt': Timestamp.now(),
          'status': 'success',
        };

        transaction.set(userVoucherRefFinal, userVoucher.toFirestore());
        transaction.update(voucherRef, {
          'claimedCount': FieldValue.increment(1),
        });
        transaction.update(userRef, {
          'points': FieldValue.increment(-voucher.exchangePoints),
        });
        transaction.set(historyRef, historyData);
      });
      return Result.success(null);
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in exchangeVoucher: $e\n$stack');
      String errMsg = 'Lỗi hệ thống Firestore';
      if (e.code == 'permission-denied') errMsg = 'Không có quyền thực hiện thao tác này.';
      if (e.code == 'not-found') errMsg = 'Tài liệu không tìm thấy.';
      if (e.code == 'already-exists') errMsg = 'Dữ liệu đã tồn tại.';
      return Result.failure(errMsg);
    } on Exception catch (e, stack) {
      debugPrint('Exception in exchangeVoucher: $e\n$stack');
      return Result.failure(e.toString().replaceAll('Exception: ', ''));
    } catch (e, stack) {
      debugPrint('Error in exchangeVoucher: $e\n$stack');
      return Result.failure('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<Result<void>> checkAndExpireUserVouchers(String userId) async {
    try {
      final now = DateTime.now();
      final query = await _service.collection('user_vouchers')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'available')
          .get();

      final batch = _service.batch();
      var hasUpdates = false;

      for (final doc in query.docs) {
        final rawExpiredAt = doc.data()['expiredAt'];
        if (rawExpiredAt == null) continue;
        final expiredAt = rawExpiredAt is Timestamp
            ? rawExpiredAt.toDate()
            : DateTime.tryParse(rawExpiredAt.toString()) ?? now;
        if (expiredAt.isBefore(now)) {
          batch.update(doc.reference, {'status': 'expired'});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
      return Result.success(null);
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in checkAndExpireUserVouchers: $e\n$stack');
      return Result.failure('Không thể cập nhật trạng thái voucher hết hạn.');
    } on Exception catch (e, stack) {
      debugPrint('Exception in checkAndExpireUserVouchers: $e\n$stack');
      return Result.failure(e.toString());
    } catch (e, stack) {
      debugPrint('Error in checkAndExpireUserVouchers: $e\n$stack');
      return Result.failure('Đã xảy ra lỗi.');
    }
  }
}
