import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../payment_model.dart';
import 'payment_countdown_widget.dart';
import 'payment_status_chip.dart';

class VietQRPaymentCard extends StatelessWidget {
  const VietQRPaymentCard({
    super.key,
    required this.payment,
    required this.status,
    required this.secondsRemaining,
    required this.onCopyAccount,
    required this.onCopyDescription,
    required this.onRefresh,
  });

  final QrPaymentModel payment;
  final PaymentStatus status;
  final int secondsRemaining;
  final VoidCallback onCopyAccount;
  final VoidCallback onCopyDescription;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('vietqr-payment-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Header row: identity + status chip
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PaymentIdentity(),
                    const SizedBox(height: 11),
                    PaymentStatusChip(status: status),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(child: _PaymentIdentity()),
                  PaymentStatusChip(status: status),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // QR image — fully contained, tappable for fullscreen
          _QrSection(payment: payment, onRetry: onRefresh),
          const SizedBox(height: 14),

          // Amount
          Text(
            formatPaymentMoney(payment.amount),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),

          // Bank info lines
          _BankInfoLine(label: 'Ngân hàng', value: payment.displayBankName),
          const SizedBox(height: 10),
          _BankInfoLine(
            label: 'Chủ tài khoản',
            value: payment.displayAccountName,
          ),
          const SizedBox(height: 10),
          _BankInfoLine(
            label: 'Số tài khoản',
            value: payment.displayAccountNumber,
            actionKey: const ValueKey('copy-bank-account'),
            onCopy: onCopyAccount,
          ),
          const SizedBox(height: 10),
          _BankInfoLine(
            label: 'Nội dung CK',
            value: payment.description,
            actionKey: const ValueKey('copy-transfer-description'),
            onCopy: onCopyDescription,
          ),
          const SizedBox(height: 16),

          PaymentCountdownWidget(
            secondsRemaining: secondsRemaining,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: 12),
          const Text(
            'Vui lòng chuyển đúng số tiền và nội dung để đơn hàng được xác nhận nhanh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QR Section — wraps the image + action row
// ─────────────────────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  const _QrSection({required this.payment, required this.onRetry});

  final QrPaymentModel payment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Responsive QR size: 52% of screen width, clamped to [200, 240]
    final screenWidth = MediaQuery.sizeOf(context).width;
    final qrSize = (screenWidth * 0.52).clamp(200.0, 240.0);

    return Column(
      children: [
        // Tappable QR card → opens fullscreen preview
        GestureDetector(
          onTap: () => _openFullscreen(context),
          child: _QrImageCard(
            payment: payment,
            size: qrSize,
            onRetry: onRetry,
          ),
        ),
        const SizedBox(height: 10),
        // Action buttons row under the QR
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QrActionButton(
              key: const ValueKey('qr-fullscreen-btn'),
              icon: Icons.zoom_in_rounded,
              label: 'Phóng to',
              onTap: () => _openFullscreen(context),
            ),
            const SizedBox(width: 12),
            _QrActionButton(
              key: const ValueKey('qr-refresh-btn'),
              icon: Icons.refresh_rounded,
              label: 'Làm mới',
              onTap: () {
                HapticFeedback.selectionClick();
                onRetry();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _QrFullscreenDialog(payment: payment),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QR Image Card — white padded card with contain-fitted network image
// ─────────────────────────────────────────────────────────────────────────────

class _QrImageCard extends StatelessWidget {
  const _QrImageCard({
    required this.payment,
    required this.size,
    required this.onRetry,
  });

  final QrPaymentModel payment;
  final double size;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final imageUrl = payment.imageUri.toString();
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        // Key by session so Flutter refetches when session changes
        cacheKey: '${imageUrl}_${payment.session}',
        // BoxFit.contain ensures the full QR is always visible — never cropped
        fit: BoxFit.contain,
        placeholder: (context, url) => const _QrShimmer(),
        errorWidget: (context, url, error) => _QrError(onRetry: onRetry),
        fadeInDuration: const Duration(milliseconds: 220),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen QR dialog
// ─────────────────────────────────────────────────────────────────────────────

class _QrFullscreenDialog extends StatelessWidget {
  const _QrFullscreenDialog({required this.payment});

  final QrPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final imageUrl = payment.imageUri.toString();
    final screenSize = MediaQuery.sizeOf(context);
    // Use 80% of the smaller dimension so it fits on any screen orientation
    final size = (screenSize.shortestSide * 0.80).clamp(200.0, 380.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR card
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              cacheKey: '${imageUrl}_${payment.session}',
              fit: BoxFit.contain,
              placeholder: (context, url) => const _QrShimmer(),
              errorWidget: (context, url, error) => const Icon(
                Icons.qr_code_rounded,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Amount label
          Text(
            formatPaymentMoney(payment.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            payment.displayBankName,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 22),
          // Close button
          FilledButton.icon(
            key: const ValueKey('qr-fullscreen-close'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Đóng'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer loading placeholder (square, no spinner)
// ─────────────────────────────────────────────────────────────────────────────

class _QrShimmer extends StatefulWidget {
  const _QrShimmer();

  @override
  State<_QrShimmer> createState() => _QrShimmerState();
}

class _QrShimmerState extends State<_QrShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment(-1.8 + (_controller.value * 3.0), 0),
              end: Alignment(-0.8 + (_controller.value * 3.0), 0),
              colors: const [
                Color(0xFFF1F3F7),
                Color(0xFFFAFBFC),
                Color(0xFFF1F3F7),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state — icon + descriptive text + retry button
// ─────────────────────────────────────────────────────────────────────────────

class _QrError extends StatelessWidget {
  const _QrError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.qr_code_rounded,
          color: AppColors.textTertiary,
          size: 38,
        ),
        const SizedBox(height: 10),
        const Text(
          'Không tải được mã QR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: OutlinedButton.icon(
            key: const ValueKey('retry-vietqr'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Tải lại QR',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pill action button under the QR
// ─────────────────────────────────────────────────────────────────────────────

class _QrActionButton extends StatelessWidget {
  const _QrActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment identity header
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentIdentity extends StatelessWidget {
  const _PaymentIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: AppColors.primary,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thanh toán VietQR',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Quét mã qua ứng dụng ngân hàng',
                maxLines: 2,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank info row
// ─────────────────────────────────────────────────────────────────────────────

class _BankInfoLine extends StatelessWidget {
  const _BankInfoLine({
    required this.label,
    required this.value,
    this.actionKey,
    this.onCopy,
  });

  final String label;
  final String value;
  final Key? actionKey;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 93,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              key: actionKey,
              tooltip: 'Sao chép',
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: const Icon(
                Icons.copy_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
