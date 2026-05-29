import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class SubmitReviewButton extends StatelessWidget {
  const SubmitReviewButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.brandGradient : null,
          color: enabled ? null : AppColors.textTertiary,
          borderRadius: BorderRadius.circular(17),
          boxShadow: enabled ? AppColors.cardShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('submit-review-button'),
            onTap: enabled && !loading ? onPressed : null,
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('submitting'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Row(
                          key: ValueKey('submit-label'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Gửi đánh giá',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
