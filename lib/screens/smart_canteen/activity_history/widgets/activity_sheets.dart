import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../activity_model.dart';
import 'activity_timeline.dart';

class ActivityDetailSheet extends StatelessWidget {
  const ActivityDetailSheet({
    super.key,
    required this.activity,
    required this.onActionTap,
  });

  final ActivityModel activity;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        11,
        20,
        MediaQuery.viewPaddingOf(context).bottom + 19,
      ),
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
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: activity.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(
                          activity.icon,
                          color: activity.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ActivityStatusChip(status: activity.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  Text(
                    activity.fullDescription,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 19),
                  _DetailLine(title: 'Thời gian', value: activity.timeLabel),
                  _DetailLine(
                    title: 'Loại hoạt động',
                    value: activityTypeLabel(activity.type),
                  ),
                  if (activity.referenceCode != null)
                    _DetailLine(
                      title: 'Mã tham chiếu',
                      value: activity.referenceCode!,
                    ),
                  if (activity.device != null)
                    _DetailLine(title: 'Thiết bị', value: activity.device!),
                  if (activity.ipAddress != null)
                    _DetailLine(
                      title: 'Địa chỉ IP',
                      value: activity.ipAddress!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              key: const ValueKey('activity-detail-action'),
              onPressed: onActionTap,
              icon: Icon(_actionIcon(activity.type), size: 19),
              label: Text(_actionLabel(activity.type)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(ActivityType type) => switch (type) {
    ActivityType.order => 'Xem đơn hàng',
    ActivityType.payment => 'Xem thanh toán',
    ActivityType.offer => 'Khám phá ưu đãi',
    ActivityType.reward => 'Xem điểm thưởng',
    ActivityType.account => 'Quản lý tài khoản',
    ActivityType.system || ActivityType.all => 'Khám phá món ăn',
  };

  IconData _actionIcon(ActivityType type) => switch (type) {
    ActivityType.order => Icons.receipt_long_outlined,
    ActivityType.payment => Icons.account_balance_wallet_outlined,
    ActivityType.offer => Icons.local_activity_outlined,
    ActivityType.reward => Icons.stars_outlined,
    ActivityType.account => Icons.manage_accounts_outlined,
    ActivityType.system || ActivityType.all => Icons.restaurant_menu_rounded,
  };
}

class ActivityFilterSheet extends StatefulWidget {
  const ActivityFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onReset,
  });

  final ActivityFilterModel initialFilter;
  final ValueChanged<ActivityFilterModel> onApply;
  final VoidCallback onReset;

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late ActivityType _type;
  ActivityStatus? _status;
  late ActivityPeriod _period;

  @override
  void initState() {
    super.initState();
    _type = widget.initialFilter.type;
    _status = widget.initialFilter.status;
    _period = widget.initialFilter.period;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 16),
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
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bộ lọc hoạt động',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChoiceSection<ActivityType>(
                      title: 'Loại hoạt động',
                      values: ActivityType.values,
                      selected: _type,
                      labelFor: activityTypeLabel,
                      onSelected: (value) => setState(() => _type = value),
                    ),
                    const SizedBox(height: 18),
                    _ChoiceSection<ActivityStatus?>(
                      title: 'Trạng thái',
                      values: const [
                        null,
                        ActivityStatus.success,
                        ActivityStatus.processing,
                        ActivityStatus.failed,
                        ActivityStatus.cancelled,
                      ],
                      selected: _status,
                      labelFor: (value) =>
                          value == null ? 'Tất cả' : activityStatusLabel(value),
                      onSelected: (value) => setState(() => _status = value),
                    ),
                    const SizedBox(height: 18),
                    _ChoiceSection<ActivityPeriod>(
                      title: 'Thời gian',
                      values: ActivityPeriod.values,
                      selected: _period,
                      labelFor: activityPeriodLabel,
                      onSelected: (value) => setState(() => _period = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('reset-activity-filter'),
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Đặt lại'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('apply-activity-filter'),
                    onPressed: () {
                      widget.onApply(
                        ActivityFilterModel(
                          type: _type,
                          status: _status,
                          period: _period,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                key: ValueKey('activity-sheet-$title-${labelFor(value)}'),
                label: Text(labelFor(value)),
                selected: value == selected,
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: value == selected
                      ? AppColors.primary
                      : AppColors.divider,
                ),
                labelStyle: TextStyle(
                  color: value == selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
