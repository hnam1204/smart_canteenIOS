import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../activity_model.dart';

class ActivityTimelineList extends StatelessWidget {
  const ActivityTimelineList({
    super.key,
    required this.groups,
    required this.onDetailsTap,
  });

  final Map<ActivityDayGroup, List<ActivityModel>> groups;
  final ValueChanged<ActivityModel> onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final populatedGroups = ActivityDayGroup.values
        .where((group) => groups[group]?.isNotEmpty ?? false)
        .toList(growable: false);
    return Column(
      children: [
        for (
          var groupIndex = 0;
          groupIndex < populatedGroups.length;
          groupIndex++
        )
          _ActivityDaySection(
            group: populatedGroups[groupIndex],
            activities: groups[populatedGroups[groupIndex]]!,
            onDetailsTap: onDetailsTap,
          ),
      ],
    );
  }
}

class _ActivityDaySection extends StatelessWidget {
  const _ActivityDaySection({
    required this.group,
    required this.activities,
    required this.onDetailsTap,
  });

  final ActivityDayGroup group;
  final List<ActivityModel> activities;
  final ValueChanged<ActivityModel> onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 17, bottom: 12),
          child: Text(
            activityDayGroupLabel(group),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var index = 0; index < activities.length; index++)
          ActivityTimelineItem(
            activity: activities[index],
            showLine: index != activities.length - 1,
            onDetailsTap: () => onDetailsTap(activities[index]),
          ),
      ],
    );
  }
}

class ActivityTimelineItem extends StatelessWidget {
  const ActivityTimelineItem({
    super.key,
    required this.activity,
    required this.showLine,
    required this.onDetailsTap,
  });

  final ActivityModel activity;
  final bool showLine;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: activity.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(activity.icon, color: activity.color, size: 21),
                ),
                if (showLine)
                  Container(width: 2, height: 77, color: AppColors.divider),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F2F6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF102A43).withValues(alpha: 0.04),
                    blurRadius: 13,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ActivityStatusChip(status: activity.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.referenceCode == null
                              ? activity.timeLabel
                              : '${activity.referenceCode}  •  ${activity.timeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      if (activity.hasDetails)
                        TextButton(
                          key: ValueKey('activity-detail-${activity.id}'),
                          onPressed: onDetailsTap,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.only(left: 8),
                            minimumSize: const Size(0, 27),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityStatusChip extends StatelessWidget {
  const ActivityStatusChip({super.key, required this.status});
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      ActivityStatus.success => (AppColors.success, const Color(0xFFDCFCE7)),
      ActivityStatus.processing => (
        const Color(0xFF2563EB),
        const Color(0xFFDBEAFE),
      ),
      ActivityStatus.failed => (
        const Color(0xFFDC2626),
        const Color(0xFFFEE2E2),
      ),
      ActivityStatus.cancelled => (AppColors.error, const Color(0xFFFFE4E6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        activityStatusLabel(status),
        style: TextStyle(
          color: colors.$1,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
