import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class ReviewCommentBox extends StatelessWidget {
  const ReviewCommentBox({
    super.key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('review-comment-field'),
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: 300,
      maxLines: 5,
      minLines: 4,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: 'Chia sẻ cảm nhận của bạn...',
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        errorText: errorText,
        filled: true,
        fillColor: AppColors.field,
        counterStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.all(15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
