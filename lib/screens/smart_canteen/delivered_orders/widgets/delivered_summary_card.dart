import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivered_status_banner.dart';

class DeliveredSummaryCard extends StatelessWidget {
  const DeliveredSummaryCard({
    super.key,
    required this.totalDelivered,
    required this.totalSpent,
    required this.awaitingReview,
    required this.rewardPoints,
  });

  final int totalDelivered;
  final int totalSpent;
  final int awaitingReview;
  final int rewardPoints;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryData(
        Icons.receipt_long_outlined,
        '$totalDelivered',
        'Đơn đã giao',
      ),
      _SummaryData(
        Icons.payments_outlined,
        formatCurrency(totalSpent),
        'Đã chi',
      ),
      _SummaryData(
        Icons.star_outline_rounded,
        '$awaitingReview',
        'Chưa đánh giá',
      ),
      _SummaryData(Icons.stars_rounded, '+$rewardPoints', 'Điểm nhận'),
    ];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFFFF4EA)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE2F1E8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 335) {
            return Wrap(
              runSpacing: 12,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: constraints.maxWidth / 2,
                      child: _SummaryItem(data: item),
                    ),
                  )
                  .toList(growable: false),
            );
          }
          return Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0)
                  Container(width: 1, height: 39, color: AppColors.divider),
                Expanded(child: _SummaryItem(data: items[index])),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(data.icon, size: 18, color: deliveredGreen),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          data.label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
