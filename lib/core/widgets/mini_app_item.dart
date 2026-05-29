import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/text_styles.dart';

class MiniAppItem extends StatelessWidget {
  const MiniAppItem({
    super.key,
    required this.label,
    this.icon,
    this.asset,
    this.onTap,
    this.tint = AppColors.primary,
  });

  final String label;
  final IconData? icon;
  final String? asset;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: asset != null
                    ? Image.asset(asset!, width: 32, height: 32)
                    : Icon(icon, color: tint, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
