import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../activity_model.dart';

class ActivityFilterTabs extends StatelessWidget {
  const ActivityFilterTabs({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final ActivityType selected;
  final int Function(ActivityType type) countFor;
  final ValueChanged<ActivityType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        key: const ValueKey('activity-filter-tabs'),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ActivityType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = ActivityType.values[index];
          final active = type == selected;
          return InkWell(
            key: ValueKey('activity-filter-${type.name}'),
            onTap: () => onSelected(type),
            borderRadius: BorderRadius.circular(23),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    activityTypeLabel(type),
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${countFor(type)}',
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
