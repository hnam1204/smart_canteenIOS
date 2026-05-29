import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class HelpBanner extends StatelessWidget {
  const HelpBanner({super.key, required this.onChatTap});

  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 17, 14, 17),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.19),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 33,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chúng tôi có thể giúp gì cho bạn?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tìm câu trả lời nhanh hoặc trò chuyện với hỗ trợ viên.',
                    style: TextStyle(
                      color: Color(0xFFFFEEE4),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('banner-chat-support'),
              tooltip: 'Chat ngay',
              onPressed: onChatTap,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
