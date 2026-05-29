import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../reward_model.dart';

class RewardSummaryCard extends StatelessWidget {
  const RewardSummaryCard({super.key, required this.points});

  final RewardPointsModel points;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryData(
        'Tích lũy',
        formatRewardPoints(points.lifetimePoints),
        Icons.add_circle_outline_rounded,
      ),
      _SummaryData(
        'Đã dùng',
        formatRewardPoints(points.usedPoints),
        Icons.redeem_outlined,
      ),
      _SummaryData(
        'Sắp hết hạn',
        formatRewardPoints(points.expiringPoints),
        Icons.schedule_rounded,
      ),
      _SummaryData(
        'Đơn tích điểm',
        '${points.eligibleOrders}',
        Icons.receipt_long_outlined,
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                for (final item in items)
                  SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: _SummaryItem(data: item),
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _SummaryItem(data: items[index])),
                if (index != items.length - 1)
                  const SizedBox(
                    height: 46,
                    child: VerticalDivider(color: AppColors.divider),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(data.icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 5),
        Text(
          data.value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          data.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
