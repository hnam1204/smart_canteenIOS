import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/utils/app_feedback.dart';
import '../../models/firestore_models.dart' as store;
import '../../providers/payment_provider.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/voucher_repository.dart';
import 'payment/payment_controller.dart' show PaymentConfirmation;
import 'payment/payment_model.dart';
import 'payment/payment_success_screen.dart';
import 'payment/widgets/cash_payment_notice.dart';
import 'payment/widgets/order_summary_card.dart';
import 'payment/widgets/payment_method_card.dart';
import 'payment/widgets/vietqr_payment_card.dart';
import 'qr_pickup/order_model.dart' as pickup;
import 'qr_pickup/qr_pickup_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, this.order = demoPaymentOrder});

  final PaymentOrderModel order;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentProvider _controller;
  final OrderRepository _orderRepository = OrderRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  final CartRepository _cartRepository = CartRepository();
  final UserRepository _userRepository = UserRepository();
  final VoucherRepository _voucherRepository = VoucherRepository();

  String? _createdOrderId;
  bool _navigatedToSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = PaymentProvider(order: widget.order);
    _controller.addListener(_handlePaymentUpdates);
    unawaited(_controller.loadPaymentSettings());
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePaymentUpdates);
    _controller.dispose();
    super.dispose();
  }

  void _handlePaymentUpdates() {
    if (!mounted || _navigatedToSuccess) return;
    if (_controller.status != PaymentStatus.paid) return;

    final createdOrderId = _createdOrderId ?? _controller.bankOrderId;
    if (createdOrderId == null || createdOrderId.isEmpty) return;

    _navigatedToSuccess = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNavigator.replace<void>(
        context,
        builder: (_) => PaymentSuccessScreen(
          order: widget.order,
          method: PaymentMethod.bankQr,
          qrPayment: _controller.qrPayment,
          pickupOrder: _pickupOrder,
          firestoreOrderId: createdOrderId,
          paidAt: _controller.paidAt ?? DateTime.now(),
        ),
      );
    });
  }

  Future<void> _copyValue(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showAppSnackBar(context, 'Đã sao chép $label.');
  }

  void _selectPaymentMethod(PaymentMethod method) {
    if (_controller.selectedMethod == PaymentMethod.bankQr &&
        _createdOrderId != null &&
        method != PaymentMethod.bankQr) {
      showAppSnackBar(
        context,
        'Đơn QR đã được tạo. Vui lòng hoàn tất hoặc tạo lại từ giỏ hàng.',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primary,
      );
      return;
    }

    _controller.selectMethod(method);
    if (method == PaymentMethod.bankQr) {
      unawaited(_ensureBankPaymentSession());
    }
  }

  Future<void> _ensureBankPaymentSession() async {
    if (_controller.creatingBankSession) return;

    if (_createdOrderId != null) {
      await _controller.bindBankOrder(
        orderId: _createdOrderId!,
        repository: _orderRepository,
      );
      return;
    }

    _controller.markBankSessionCreating(true);
    try {
      final createdOrderId = await _persistCheckout(paymentStatus: 'pending');
      if (!mounted || createdOrderId == null) return;
      _createdOrderId = createdOrderId;
      await _controller.bindBankOrder(
        orderId: createdOrderId,
        repository: _orderRepository,
      );
    } finally {
      _controller.markBankSessionCreating(false);
    }
  }

  void _refreshBankQr() {
    _controller.refreshQr();
    if (_createdOrderId == null) {
      unawaited(_ensureBankPaymentSession());
    }
    showAppSnackBar(context, 'Mã VietQR mới đã sẵn sàng.');
  }

  Future<void> _confirmPayment() async {
    if (_controller.selectedMethod == PaymentMethod.bankQr) {
      await _ensureBankPaymentSession();
      return;
    }

    final confirmation = await _controller.confirmPayment();
    if (!mounted) return;

    if (confirmation == PaymentConfirmation.expired) {
      showAppSnackBar(
        context,
        'Mã QR đã hết hạn. Vui lòng thử lại với mã mới.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return;
    }

    final createdOrderId = await _persistCheckout(paymentStatus: 'unpaid');
    if (!mounted || createdOrderId == null) return;

    await AppNavigator.replace<void>(
      context,
      builder: (_) =>
          QRPickupScreen(orderId: createdOrderId, previewOrder: _pickupOrder),
    );
  }

  Future<void> _confirmManualBankTransfer() async {
    if (_controller.manualTransferSubmitting ||
        _controller.customerConfirmedTransfer ||
        _controller.status == PaymentStatus.paid) {
      return;
    }

    await _ensureBankPaymentSession();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final expired = _controller.status == PaymentStatus.expired;
        return AlertDialog(
          title: const Text('Xác nhận đã chuyển khoản?'),
          content: Text(
            expired
                ? 'QR đã hết hạn. Nếu bạn đã chuyển khoản, vui lòng gửi yêu cầu xác nhận để admin kiểm tra.'
                : 'Vui lòng chỉ xác nhận khi bạn đã chuyển khoản đúng số tiền và đúng nội dung chuyển khoản. Hệ thống sẽ kiểm tra và cập nhật sau.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tôi đã chuyển khoản'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _submitManualBankTransfer();
  }

  Future<void> _submitManualBankTransfer() async {
    final orderId = (_createdOrderId ?? _controller.bankOrderId ?? '').trim();
    if (orderId.isEmpty) {
      showAppSnackBar(
        context,
        'Không tìm thấy mã đơn hàng để xác nhận.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return;
    }

    if (Firebase.apps.isEmpty) {
      _controller.markCustomerTransferConfirmed();
      showAppSnackBar(context, 'Đã gửi yêu cầu xác nhận chuyển khoản.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showAppSnackBar(
        context,
        'Bạn cần đăng nhập để gửi yêu cầu xác nhận.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return;
    }

    _controller.setManualTransferSubmitting(true);
    try {
      final result = await _orderRepository.confirmCustomerBankTransfer(
        orderId: orderId,
        userId: user.uid,
        paymentId: 'PAY-$orderId',
      );
      if (!mounted) return;
      _controller.markCustomerTransferConfirmed();
      showAppSnackBar(
        context,
        result.alreadyConfirmed
            ? 'Yêu cầu xác nhận đã được gửi trước đó.'
            : 'Đã gửi yêu cầu xác nhận chuyển khoản.',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
      );
    } catch (error) {
      debugPrint('Manual bank transfer confirmation failed: $error');
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Không thể gửi yêu cầu xác nhận. Vui lòng thử lại.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
    } finally {
      _controller.setManualTransferSubmitting(false);
    }
  }

  String get _firestoreOrderId {
    if (Firebase.apps.isEmpty) return widget.order.id;
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? widget.order.id : '${widget.order.id}_${user.uid}';
  }

  Future<String?> _persistCheckout({required String paymentStatus}) async {
    try {
      if (Firebase.apps.isEmpty) return widget.order.id;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return null;
        showAppSnackBar(
          context,
          'Bạn cần đăng nhập để tạo đơn hàng.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
        );
        return null;
      }

      final now = DateTime.now();
      final isBankQr = _controller.selectedMethod == PaymentMethod.bankQr;
      final profile = await _userRepository.getUser(user.uid);
      final customerName = profile?.fullName.trim().isNotEmpty == true
          ? profile!.fullName.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : user.email ?? '');
      final customerPhone = profile?.phone.trim() ?? '';
      final createdDocId = _firestoreOrderId;
      final pickupToken = _generatePickupToken(createdDocId, now);
      final userVoucherId = widget.order.voucherId;
      store.UserVoucherModel? userVoucher;
      if (userVoucherId != null) {
        try {
          userVoucher = await _voucherRepository.getUserVoucherById(
            userVoucherId,
          );
        } catch (error) {
          debugPrint('User voucher lookup skipped: $error');
        }
      }
      final baseVoucherId = userVoucher?.voucherId ?? widget.order.voucherId;
      final qrCodeData = jsonEncode({
        'orderId': createdDocId,
        'orderCode': widget.order.id,
        'pickupToken': pickupToken,
      });
      final orderResult = await _orderRepository.createOrder(
        store.OrderModel(
          id: createdDocId,
          userId: user.uid,
          orderCode: widget.order.id,
          items: widget.order.items
              .map(
                (item) => store.OrderItemModel(
                  foodId: item.foodId,
                  name: item.name,
                  imageUrl: item.imageAsset,
                  basePrice: item.resolvedBasePrice,
                  quantity: item.quantity,
                  note: item.note,
                  selectedToppings: item.selectedToppings
                      .map(
                        (topping) => store.ToppingModel(
                          id: topping.id,
                          name: topping.name,
                          price: topping.price,
                        ),
                      )
                      .toList(growable: true),
                  toppingTotal: item.toppingTotal,
                  itemTotal: item.total,
                ),
              )
              .toList(growable: true),
          totalAmount: widget.order.total,
          paymentMethod: isBankQr ? 'bankQr' : 'cash',
          paymentStatus: paymentStatus,
          orderStatus: 'pending',
          pickupCounter: 'Quầy A',
          note: '',
          createdAt: now,
          updatedAt: now,
          pickupEnabled: true,
          qrCodeData: qrCodeData,
          pickupToken: pickupToken,
          customerName: customerName,
          customerPhone: customerPhone,
          totalItems: widget.order.items.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ),
          subtotal: widget.order.subtotal,
          deliveryFee: widget.order.serviceFee,
          voucherDiscount: widget.order.voucherDiscount,
          voucherId: baseVoucherId,
          voucherCode: userVoucher?.voucherCode ?? widget.order.voucherCode,
          voucherTitle: userVoucher?.title ?? widget.order.voucherTitle,
          counterId: 'counter-a',
          counterName: 'Quầy A',
        ),
        userVoucherId: userVoucherId,
        discountAmount: widget.order.voucherDiscount,
      );

      if (!orderResult.isSuccess || orderResult.data == null) {
        if (!mounted) return null;
        showAppSnackBar(
          context,
          'Không thể tạo đơn hàng.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
        );
        return null;
      }

      final createdOrderId = orderResult.data!;
      if (isBankQr) {
        await _paymentRepository.createPendingBankPayment(
          id: 'PAY-$createdOrderId',
          orderId: createdOrderId,
          userId: user.uid,
          amount: widget.order.total,
          description: _controller.qrPayment.description,
        );
      }

      try {
        await _cartRepository.clear(user.uid);
      } catch (error) {
        debugPrint('Clear cart after checkout failed: $error');
      }
      return createdOrderId;
    } catch (error) {
      debugPrint('Persist checkout error: $error');
      if (!mounted) return null;
      showAppSnackBar(
        context,
        'Không thể lưu đơn hàng. Vui lòng thử lại.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return null;
    }
  }

  String _generatePickupToken(String orderId, DateTime createdAt) {
    final random = Random.secure();
    final salt = List<int>.generate(12, (_) => random.nextInt(256));
    final raw = List<int>.from(
      utf8.encode('$orderId:${createdAt.microsecondsSinceEpoch}'),
      growable: true,
    )..addAll(salt);
    return base64UrlEncode(raw).replaceAll('=', '');
  }

  pickup.OrderModel get _pickupOrder {
    final now = DateTime.now();
    final readyMinutes = now.add(const Duration(minutes: 15));

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final placedAt =
        '${twoDigits(now.day)}/${twoDigits(now.month)}/${now.year} - '
        '${twoDigits(now.hour)}:${twoDigits(now.minute)}';
    final readyAt =
        '${twoDigits(readyMinutes.hour)}:${twoDigits(readyMinutes.minute)}';
    final isBankQr = _controller.selectedMethod == PaymentMethod.bankQr;

    return pickup.OrderModel(
      id: widget.order.id,
      placedAt: placedAt,
      readyAt: readyAt,
      pickupCounter: 'Quầy A',
      pickupDescription: widget.order.items.isEmpty
          ? 'Đơn hàng'
          : widget.order.items.first.name,
      paymentStatus: isBankQr ? 'pending' : 'unpaid',
      paymentMethod: isBankQr ? 'bankQr' : 'cash',
      orderStatus: 'pending',
      isCancelled: false,
      pickupEnabled: true,
      items: widget.order.items
          .map(
            (item) => pickup.OrderItemModel(
              name: item.name,
              quantity: item.quantity,
              price: item.unitPrice,
              imageAsset: item.imageAsset,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _PaymentHeader(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: ListView(
                        key: const ValueKey('payment-content-list'),
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          MediaQuery.sizeOf(context).width < 370 ? 14 : 18,
                          7,
                          MediaQuery.sizeOf(context).width < 370 ? 14 : 18,
                          22,
                        ),
                        children: [
                          OrderSummaryCard(order: widget.order),
                          const SizedBox(height: 14),
                          PaymentMethodSection(
                            selectedMethod: _controller.selectedMethod,
                            onSelected: _selectPaymentMethod,
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(
                                    Tween(
                                      begin: const Offset(0, 0.025),
                                      end: Offset.zero,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child:
                                _controller.selectedMethod == PaymentMethod.cash
                                ? const CashPaymentNotice()
                                : VietQRPaymentCard(
                                    payment: _controller.qrPayment,
                                    status: _controller.status,
                                    secondsRemaining:
                                        _controller.secondsRemaining,
                                    onCopyAccount: () => _copyValue(
                                      _controller
                                          .qrPayment
                                          .displayAccountNumber,
                                      'số tài khoản',
                                    ),
                                    onCopyDescription: () => _copyValue(
                                      _controller.qrPayment.description,
                                      'nội dung chuyển khoản',
                                    ),
                                    onRefresh: _refreshBankQr,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              _controller.selectedMethod == PaymentMethod.bankQr
              ? _BankRealtimeBar(
                  amount: widget.order.total,
                  creating: _controller.creatingBankSession,
                  status: _controller.status,
                  errorMessage: _controller.errorMessage,
                  manualTransferSubmitting:
                      _controller.manualTransferSubmitting,
                  manualTransferConfirmed:
                      _controller.customerConfirmedTransfer,
                  onManualTransferConfirm: _confirmManualBankTransfer,
                )
              : _PaymentBottomBar(
                  amount: widget.order.total,
                  paymentMethod: _controller.selectedMethod,
                  loading: _controller.submitting,
                  onConfirm: _confirmPayment,
                ),
        );
      },
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
              color: AppColors.textPrimary,
            ),
          ),
          const Expanded(
            child: Text(
              'Thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 58),
        ],
      ),
    );
  }
}

class _BankRealtimeBar extends StatelessWidget {
  const _BankRealtimeBar({
    required this.amount,
    required this.creating,
    required this.status,
    required this.errorMessage,
    required this.manualTransferSubmitting,
    required this.manualTransferConfirmed,
    required this.onManualTransferConfirm,
  });

  final int amount;
  final bool creating;
  final PaymentStatus status;
  final String? errorMessage;
  final bool manualTransferSubmitting;
  final bool manualTransferConfirmed;
  final VoidCallback onManualTransferConfirm;

  @override
  Widget build(BuildContext context) {
    final expired = status == PaymentStatus.expired;
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: expired || hasError
                        ? const Color(0xFFFFEEEE)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: creating
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          manualTransferConfirmed
                              ? Icons.fact_check_outlined
                              : expired || hasError
                              ? Icons.error_outline_rounded
                              : Icons.sensors_rounded,
                          color: manualTransferConfirmed
                              ? AppColors.primary
                              : expired || hasError
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (manualTransferConfirmed)
                        const Text(
                          'Đã gửi yêu cầu xác nhận chuyển khoản',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      else
                        Text(
                          creating
                              ? 'Đang tạo đơn thanh toán'
                              : expired
                              ? 'QR đã hết hạn'
                              : hasError
                              ? errorMessage!
                              : 'Đang chờ thanh toán tự động',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: expired || hasError
                                ? AppColors.error
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 3),
                      if (manualTransferConfirmed)
                        const Text(
                          'Admin sẽ kiểm tra giao dịch và xác nhận thanh toán trong ít phút.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          formatPaymentMoney(amount),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!creating &&
                    !expired &&
                    !hasError &&
                    !manualTransferConfirmed)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _ManualTransferButton(
              loading: manualTransferSubmitting,
              confirmed: manualTransferConfirmed,
              onPressed: creating || manualTransferSubmitting
                  ? null
                  : manualTransferConfirmed
                  ? null
                  : onManualTransferConfirm,
            ),
            if (manualTransferConfirmed) ...[
              const SizedBox(height: 9),
              const _ManualTransferReviewNotice(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManualTransferButton extends StatelessWidget {
  const _ManualTransferButton({
    required this.loading,
    required this.confirmed,
    required this.onPressed,
  });

  final bool loading;
  final bool confirmed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        key: const ValueKey('manual-transfer-confirm'),
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Icon(
                confirmed
                    ? Icons.check_circle_outline_rounded
                    : Icons.receipt_long_rounded,
                size: 19,
              ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            confirmed
                ? 'Đã gửi yêu cầu xác nhận'
                : 'Tôi đã chuyển khoản thành công',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: confirmed ? AppColors.divider : AppColors.primary,
          disabledBackgroundColor: confirmed
              ? AppColors.divider
              : AppColors.primary.withValues(alpha: 0.62),
          foregroundColor: confirmed ? AppColors.textSecondary : Colors.white,
          disabledForegroundColor: confirmed
              ? AppColors.textSecondary
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _ManualTransferReviewNotice extends StatelessWidget {
  const _ManualTransferReviewNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD7AA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đang chờ admin xác nhận',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Yêu cầu xác nhận đã được gửi. Bạn không cần bấm lại.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBottomBar extends StatelessWidget {
  const _PaymentBottomBar({
    required this.amount,
    required this.paymentMethod,
    required this.loading,
    required this.onConfirm,
  });

  final int amount;
  final PaymentMethod paymentMethod;
  final bool loading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 350;
            final amountWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatPaymentMoney(amount),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );

            final button = _ConfirmButton(
              loading: loading,
              label: paymentMethod == PaymentMethod.cash
                  ? 'Xác nhận đơn'
                  : 'Đang chờ tự động',
              onPressed: loading ? null : onConfirm,
            );

            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  amountWidget,
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: button),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: amountWidget),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.brandGradient,
        color: onPressed == null ? AppColors.divider : null,
        borderRadius: BorderRadius.circular(15),
      ),
      child: FilledButton(
        key: const ValueKey('confirm-payment'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('payment-submitting'),
                  height: 21,
                  width: 21,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : FittedBox(
                  key: const ValueKey('payment-confirm-label'),
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 18),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
