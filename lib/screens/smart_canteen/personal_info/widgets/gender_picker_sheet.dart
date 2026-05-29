import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../user_profile_model.dart';

class GenderPickerSheet extends StatelessWidget {
  const GenderPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Gender selected;
  final ValueChanged<Gender> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 17),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chọn giới tính',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            for (final gender in Gender.values)
              ListTile(
                key: ValueKey('gender-${gender.name}'),
                onTap: () => onSelected(gender),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: selected == gender ? AppColors.primarySoft : null,
                title: Text(
                  genderLabel(gender),
                  style: TextStyle(
                    fontWeight: selected == gender
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected == gender
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  selected == gender
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected == gender
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
