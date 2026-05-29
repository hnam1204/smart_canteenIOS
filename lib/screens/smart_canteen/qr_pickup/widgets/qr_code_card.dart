import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';

class QRCodeCard extends StatelessWidget {
  const QRCodeCard({
    super.key,
    required this.order,
    required this.qrData,
    required this.secondsRemaining,
    required this.onCopyTap,
    required this.onRefreshTap,
  });

  final OrderModel order;
  final String qrData;
  final int secondsRemaining;
  final VoidCallback onCopyTap;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final qrSize = compact ? 150.0 : 180.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        18,
        compact ? 16 : 20,
        20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mã đơn hàng',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.id,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: compact ? 19 : 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          key: const ValueKey('copy-order-id'),
                          tooltip: 'Sao chép mã đơn',
                          onPressed: onCopyTap,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _paymentBadge(order).background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _paymentBadge(order).label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _paymentBadge(order).foreground,
                      fontSize: compact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          const Center(
            child: Text(
              'Đưa mã QR này cho nhân viên tại quầy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Container(
                key: ValueKey(qrData),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.045),
                      blurRadius: 13,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: qrSize,
                  padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Center(
            child: TextButton.icon(
              key: const ValueKey('refresh-qr'),
              onPressed: onRefreshTap,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                secondsRemaining > 0
                    ? 'Làm mới mã QR (${secondsRemaining}s)'
                    : 'Tải lại mã nhận món',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _PaymentBadgeStyle _paymentBadge(OrderModel order) {
    if (order.paymentStatus == 'paid') {
      return const _PaymentBadgeStyle(
        label: 'Đã thanh toán',
        foreground: AppColors.success,
        background: Color(0xFFEAF8EE),
      );
    }
    if (order.paymentStatus == 'pending' && order.paymentMethod == 'bankQr') {
      return const _PaymentBadgeStyle(
        label: 'Chờ xác nhận chuyển khoản',
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    }
    if (order.paymentStatus == 'unpaid' && order.paymentMethod == 'cash') {
      return const _PaymentBadgeStyle(
        label: 'Thanh toán tại quầy',
        foreground: Color(0xFF1976D2),
        background: Color(0xFFEAF4FF),
      );
    }
    return const _PaymentBadgeStyle(
      label: 'Đang xử lý thanh toán',
      foreground: AppColors.textSecondary,
      background: AppColors.surfaceSoft,
    );
  }
}

class _PaymentBadgeStyle {
  const _PaymentBadgeStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
