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
import 'payment/payment_controller.dart' show PaymentConfirmation;
import 'payment/payment_model.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = PaymentProvider(order: widget.order);
    _controller.loadPaymentSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyValue(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showAppSnackBar(context, 'Đã sao chép $label.');
  }

  Future<void> _confirmPayment() async {
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

    final createdOrderId = await _persistCheckout(
      paymentStatus: _controller.selectedMethod == PaymentMethod.bankQr
          ? 'pending'
          : 'unpaid',
    );

    if (!mounted || createdOrderId == null) return;

    await AppNavigator.replace<void>(
      context,
      builder: (_) =>
          QRPickupScreen(orderId: createdOrderId, previewOrder: _pickupOrder),
    );
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

      final orderResult = await OrderRepository().createOrder(
        store.OrderModel(
          id: _firestoreOrderId,
          userId: user.uid,
          orderCode: widget.order.id,
          items: widget.order.items
              .map(
                (item) => store.OrderItemModel(
                  foodId: item.name,
                  name: item.name,
                  imageUrl: item.imageAsset,
                  basePrice: item.unitPrice,
                  quantity: item.quantity,
                  note: item.note,
                ),
              )
              .toList(growable: false),
          totalAmount: widget.order.total,
          paymentMethod: _controller.selectedMethod.name,
          paymentStatus: paymentStatus,
          orderStatus: _controller.selectedMethod == PaymentMethod.bankQr
              ? 'preparing'
              : 'pending',
          pickupCounter: 'Quầy A',
          note: widget.order.voucherCode == null
              ? ''
              : 'Voucher: ${widget.order.voucherCode}',
          createdAt: now,
          updatedAt: now,
          pickupEnabled: true,
          qrCodeData: widget.order.id,
        ),
        userVoucherId: widget.order.voucherId,
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

      if (_controller.selectedMethod == PaymentMethod.bankQr) {
        await PaymentRepository().createPendingBankPayment(
          id: 'PAY-$createdOrderId',
          orderId: createdOrderId,
          userId: user.uid,
          amount: widget.order.total,
          description: _controller.qrPayment.description,
        );
      }

      await CartRepository().clear(user.uid);

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

  pickup.OrderModel get _pickupOrder {
    final now = DateTime.now();

    final placedAt =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final readyMinutes = now.add(const Duration(minutes: 15));

    final readyAt =
        '${readyMinutes.hour.toString().padLeft(2, '0')}:${readyMinutes.minute.toString().padLeft(2, '0')}';

    return pickup.OrderModel(
      id: widget.order.id,
      placedAt: placedAt,
      readyAt: readyAt,
      pickupCounter: 'Quầy A',
      pickupDescription: widget.order.items.isEmpty
          ? 'Đơn hàng'
          : widget.order.items.first.name,
      paymentStatus: _controller.selectedMethod == PaymentMethod.bankQr
          ? 'pending'
          : 'unpaid',
      paymentMethod: _controller.selectedMethod.name,
      orderStatus: _controller.selectedMethod == PaymentMethod.bankQr
          ? 'preparing'
          : 'pending',
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
                            onSelected: _controller.selectMethod,
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
                                    onRefresh: () {
                                      _controller.refreshQr();
                                      showAppSnackBar(
                                        context,
                                        'Mã VietQR mới đã sẵn sàng.',
                                      );
                                    },
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
          bottomNavigationBar: _PaymentBottomBar(
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
                letterSpacing: -0.25,
              ),
            ),
          ),
          const SizedBox(width: 58),
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
                  : 'Gửi yêu cầu xác nhận',
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
