import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../voucher_model.dart';

class FeaturedVoucherBanner extends StatelessWidget {
  const FeaturedVoucherBanner({
    super.key,
    required this.voucher,
    required this.onExplore,
  });

  final VoucherModel voucher;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFF4D6)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD59A)),
        ),
        child: Row(
          children: [
            Container(
              width: 53,
              height: 53,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.primary,
                size: 29,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ưu đãi đặc biệt hôm nay',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher.valueLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('explore-featured-vouchers'),
              onPressed: onExplore,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Khám phá'),
            ),
          ],
        ),
      ),
    );
  }
}
