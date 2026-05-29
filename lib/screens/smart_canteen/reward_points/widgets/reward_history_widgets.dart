import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../reward_model.dart';

class RewardHistoryTabs extends StatelessWidget {
  const RewardHistoryTabs({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final RewardHistoryFilter selected;
  final int Function(RewardHistoryFilter) countFor;
  final ValueChanged<RewardHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: const ValueKey('reward-history-tabs'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: RewardHistoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = RewardHistoryFilter.values[index];
          final active = filter == selected;
          return InkWell(
            key: ValueKey('reward-filter-${filter.name}'),
            onTap: () => onSelected(filter),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _labelFor(filter),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${countFor(filter)}',
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.primary,
                        fontSize: 10.5,
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

  String _labelFor(RewardHistoryFilter filter) => switch (filter) {
    RewardHistoryFilter.all => 'Tất cả',
    RewardHistoryFilter.earned => 'Tích điểm',
    RewardHistoryFilter.redeemed => 'Đổi thưởng',
    RewardHistoryFilter.expired => 'Hết hạn',
  };
}

class RewardHistoryItem extends StatelessWidget {
  const RewardHistoryItem({super.key, required this.history});

  final RewardHistoryModel history;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(history);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF0F2F6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(palette.icon, color: palette.foreground, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  history.orderId == null
                      ? history.timeLabel
                      : '${history.orderId}  •  ${history.timeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${history.points > 0 ? '+' : ''}${formatRewardPoints(history.points)}',
                style: TextStyle(
                  color: history.points > 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                rewardStatusLabel(history.status),
                style: TextStyle(
                  color: palette.foreground,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _HistoryPalette _paletteFor(RewardHistoryModel item) {
    if (item.status == RewardStatus.expired) {
      return const _HistoryPalette(
        Icons.history_toggle_off_rounded,
        AppColors.error,
        Color(0xFFFEE2E2),
      );
    }
    if (item.type == RewardHistoryType.earned) {
      return const _HistoryPalette(
        Icons.add_circle_outline_rounded,
        AppColors.success,
        Color(0xFFDCFCE7),
      );
    }
    if (item.type == RewardHistoryType.redeemed) {
      return const _HistoryPalette(
        Icons.card_giftcard_rounded,
        AppColors.primary,
        AppColors.primarySoft,
      );
    }
    return const _HistoryPalette(
      Icons.schedule_rounded,
      AppColors.warning,
      Color(0xFFFEF3C7),
    );
  }
}

class _HistoryPalette {
  const _HistoryPalette(this.icon, this.foreground, this.background);
  final IconData icon;
  final Color foreground;
  final Color background;
}
