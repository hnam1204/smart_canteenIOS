import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.edit_note_rounded,
          size: 29,
          color: AppColors.primary,
        ),
      ),
      title: const Text(
        'Bỏ thay đổi?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'Thông tin bạn vừa chỉnh sửa chưa được lưu.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tiếp tục sửa'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const ValueKey('discard-personal-changes'),
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Bỏ thay đổi'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
