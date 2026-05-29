import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../qr_pickup/order_model.dart' as pickup;
import '../qr_pickup/qr_pickup_screen.dart';
import '../smart_canteen_home_screen.dart';
import 'payment_model.dart';
import 'widgets/payment_success_widgets.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.order,
    required this.method,
    required this.pickupOrder,
    required this.firestoreOrderId,
    required this.paidAt,
    this.qrPayment,
  });

  final PaymentOrderModel order;
  final PaymentMethod method;
  final QrPaymentModel? qrPayment;
  final pickup.OrderModel pickupOrder;
  final String firestoreOrderId;
  final DateTime paidAt;

  void _openPickupQr(BuildContext context) {
    AppNavigator.push<void>(
      context,
      builder: (_) =>
          QRPickupScreen(orderId: firestoreOrderId, previewOrder: pickupOrder),
    );
  }

  void _goHome(BuildContext context) {
    AppNavigator.replace<void>(
      context,
      builder: (_) => const SmartCanteenHomeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 370
        ? 14.0
        : 18.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SuccessHeader(method: method, onHome: () => _goHome(context)),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    key: const ValueKey('payment-success-content'),
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      4,
                      horizontalPadding,
                      24,
                    ),
                    children: [
                      PaymentSuccessHero(method: method),
                      const SizedBox(height: 14),
                      PaymentInfoCard(
                        order: order,
                        method: method,
                        qrPayment: qrPayment,
                        paidAt: paidAt,
                      ),
                      const SizedBox(height: 14),
                      SuccessOrderSummaryCard(order: order),
                      const SizedBox(height: 14),
                      PickupInfoCard(order: pickupOrder),
                      const SizedBox(height: 18),
                      SuccessActionButtons(
                        onPickupQr: () => _openPickupQr(context),
                        onHome: () => _goHome(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.method, required this.onHome});

  final PaymentMethod method;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(
            child: Text(
              method == PaymentMethod.cash
                  ? 'Đặt món thành công'
                  : 'Thanh toán thành công',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: IconButton(
              key: const ValueKey('payment-success-header-home'),
              tooltip: 'Trang chủ',
              onPressed: onHome,
              icon: const Icon(Icons.home_outlined),
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
