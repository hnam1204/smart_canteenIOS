import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../../qr_pickup/order_model.dart' as pickup;
import '../payment_model.dart';

class PaymentSuccessHero extends StatelessWidget {
  const PaymentSuccessHero({super.key, required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 470),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.45, end: 1),
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              height: 74,
              width: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.16),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            method == PaymentMethod.cash
                ? 'Cảm ơn bạn đã đặt món!'
                : 'Cảm ơn bạn đã thanh toán!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            method == PaymentMethod.cash
                ? 'Đơn hàng đã được tiếp nhận. Vui lòng thanh toán tại quầy khi nhận món.'
                : 'Đơn hàng của bạn đã được xác nhận và đang được chuẩn bị.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({
    super.key,
    required this.order,
    required this.method,
    required this.qrPayment,
    required this.paidAt,
  });

  final PaymentOrderModel order;
  final PaymentMethod method;
  final QrPaymentModel? qrPayment;
  final DateTime paidAt;

  bool get _paidByTransfer => method == PaymentMethod.bankQr;

  @override
  Widget build(BuildContext context) {
    return _SuccessCard(
      title: 'Thông tin thanh toán',
      child: Column(
        children: [
          _InformationLine(label: 'Mã đơn hàng', value: order.id),
          const SizedBox(height: 12),
          _InformationLine(
            label: 'Trạng thái',
            trailing: _PaymentStateChip(cashOnPickup: !_paidByTransfer),
          ),
          const SizedBox(height: 12),
          _InformationLine(
            label: 'Phương thức',
            value: _paidByTransfer
                ? 'Chuyển khoản ngân hàng'
                : 'Tiền mặt tại quầy',
          ),
          if (_paidByTransfer && qrPayment != null) ...[
            const SizedBox(height: 12),
            const _InformationLine(
              label: 'Ngân hàng',
              value: QrPaymentModel.bankName,
            ),
            const SizedBox(height: 12),
            const _InformationLine(
              label: 'Chủ tài khoản',
              value: QrPaymentModel.accountHolder,
            ),
            const SizedBox(height: 12),
            const _InformationLine(
              label: 'Số tài khoản',
              value: QrPaymentModel.accountNumber,
            ),
            const SizedBox(height: 12),
            _InformationLine(
              label: 'Nội dung CK',
              value: qrPayment!.description,
            ),
          ],
          const SizedBox(height: 12),
          _InformationLine(label: 'Thời gian', value: _formatPaidTime(paidAt)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _InformationLine(
            label: 'Tổng tiền',
            value: formatPaymentMoney(order.total),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class SuccessOrderSummaryCard extends StatelessWidget {
  const SuccessOrderSummaryCard({super.key, required this.order});

  final PaymentOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SuccessCard(
      title: 'Đơn hàng đã đặt',
      child: Column(
        children: [
          for (var index = 0; index < order.items.length; index++) ...[
            _SuccessItemTile(item: order.items[index]),
            if (index != order.items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.divider),
              ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _PriceLine(label: 'Tạm tính', amount: order.subtotal),
          const SizedBox(height: 9),
          _PriceLine(label: 'Giảm giá', amount: -order.voucherDiscount),
          const SizedBox(height: 9),
          _PriceLine(label: 'Phí dịch vụ', amount: order.serviceFee),
          const SizedBox(height: 14),
          _PriceLine(label: 'Tổng cộng', amount: order.total, emphasized: true),
        ],
      ),
    );
  }
}

class PickupInfoCard extends StatelessWidget {
  const PickupInfoCard({super.key, required this.order});

  final pickup.OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDAC0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quầy nhận món',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.pickupCounter} - ${order.pickupDescription}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Dự kiến nhận',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.readyAt,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng đưa mã QR cho nhân viên tại quầy để nhận món.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
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

class SuccessActionButtons extends StatelessWidget {
  const SuccessActionButtons({
    super.key,
    required this.onPickupQr,
    required this.onHome,
  });

  final VoidCallback onPickupQr;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: FilledButton.icon(
            key: const ValueKey('payment-success-qr'),
            onPressed: onPickupQr,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text(
              'Xem mã QR nhận món',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('payment-success-home'),
            onPressed: onHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.home_outlined, size: 20),
            label: const Text(
              'Về trang chủ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _InformationLine extends StatelessWidget {
  const _InformationLine({
    required this.label,
    this.value,
    this.trailing,
    this.emphasized = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child:
              trailing ??
              Text(
                value ?? '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: emphasized ? AppColors.primary : AppColors.textPrimary,
                  fontSize: emphasized ? 18 : 12.5,
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
        ),
      ],
    );
  }
}

class _PaymentStateChip extends StatelessWidget {
  const _PaymentStateChip({required this.cashOnPickup});

  final bool cashOnPickup;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cashOnPickup ? AppColors.primarySoft : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          cashOnPickup ? 'Thanh toán tại quầy' : 'Đã thanh toán',
          style: TextStyle(
            color: cashOnPickup ? AppColors.primary : AppColors.success,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SuccessItemTile extends StatelessWidget {
  const _SuccessItemTile({required this.item});

  final PaymentOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: AppFoodImage(
            source: item.imageAsset,
            width: 54,
            height: 54,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'x${item.quantity}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatPaymentMoney(item.total),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final int amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: emphasized ? 15 : 12.5,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          formatPaymentMoney(amount),
          style: TextStyle(
            color: emphasized ? AppColors.primary : AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasized ? 20 : 12.5,
          ),
        ),
      ],
    );
  }
}

String _formatPaidTime(DateTime dateTime) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(dateTime.day)}/${twoDigits(dateTime.month)}/${dateTime.year}'
      ' - ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}
