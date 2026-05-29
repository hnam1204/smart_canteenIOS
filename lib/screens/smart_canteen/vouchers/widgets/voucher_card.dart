import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../voucher_model.dart';

class VoucherCard extends StatelessWidget {
  const VoucherCard({
    super.key,
    required this.voucher,
    required this.onCopy,
    required this.onDetails,
    required this.onUse,
    this.isClaimLabel = false,
  });

  final VoucherModel voucher;
  final VoidCallback onCopy;
  final VoidCallback onDetails;
  final VoidCallback onUse;
  final bool isClaimLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = voucher.canUse;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: voucher.isFeatured
              ? const Color(0xFFFFD6B8)
              : AppColors.divider,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppColors.primarySoft
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      voucher.icon,
                      color: enabled
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                voucher.code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            InkWell(
                              key: ValueKey('copy-voucher-${voucher.id}'),
                              onTap: onCopy,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(5),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  VoucherStatusChip(status: voucher.status),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(height: 16, width: double.infinity),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomPaint(painter: _DashedLinePainter()),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_TicketNotch(), _TicketNotch()],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher.valueLabel,
                              style: TextStyle(
                                color: enabled
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voucher.condition,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.35,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        voucher.validUntil,
                        style: const TextStyle(
                           color: AppColors.textTertiary,
                           fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: voucher.expiryProgress,
                        minHeight: 4,
                        color: voucher.status == VoucherStatus.expiringSoon
                            ? AppColors.warning
                            : AppColors.primary,
                        backgroundColor: AppColors.primarySoft,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: ValueKey('detail-voucher-${voucher.id}'),
                          onPressed: onDetails,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: Color(0xFFFFC79D)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Chi tiết'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FilledButton(
                          key: ValueKey('use-voucher-${voucher.id}'),
                          onPressed: enabled ? onUse : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.surfaceSoft,
                            disabledForegroundColor: AppColors.textTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isClaimLabel ? 'Lấy mã ngay' : 'Dùng ngay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoucherStatusChip extends StatelessWidget {
  const VoucherStatusChip({super.key, required this.status});

  final VoucherStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      VoucherStatus.available => (const Color(0xFFDCFCE7), AppColors.success),
      VoucherStatus.expiringSoon => (
        const Color(0xFFFEF3C7),
        AppColors.warning,
      ),
      VoucherStatus.used => (AppColors.surfaceSoft, AppColors.textSecondary),
      VoucherStatus.expired => (const Color(0xFFFEE2E2), AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        voucherStatusLabel(status),
        style: TextStyle(
          color: colors.$2,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TicketNotch extends StatelessWidget {
  const _TicketNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 12.0;
    while (x < size.width - 12) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width - 12), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
