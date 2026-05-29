import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/text_styles.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.height = 250,
    this.centered = false,
    this.logoAsset = 'assets/logos/huflit_logo.png',
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final double height;
  final bool centered;
  final String logoAsset;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            bottom: -34,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(logoAsset, width: 185, height: 185),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              child: Column(
                crossAxisAlignment: alignment,
                children: [
                  if (leading != null || trailing != null)
                    Row(children: [?leading, const Spacer(), ?trailing]),
                  if (centered) const Spacer(),
                  if (centered)
                    Container(
                      height: 66,
                      width: 66,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(logoAsset),
                    ),
                  Text(
                    subtitle,
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: AppTextStyles.heading.copyWith(color: Colors.white),
                  ),
                  if (!centered) const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
