import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../user_profile_model.dart';

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({super.key, required this.stats});

  final ProfileStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData(Icons.stars_rounded, '${stats.points}', 'Điểm thưởng'),
      _StatData(Icons.workspace_premium_outlined, stats.memberTier, 'Hạng'),
      _StatData(
        Icons.shopping_bag_outlined,
        '${stats.orderCount}',
        'Đơn đã mua',
      ),
      _StatData(
        Icons.account_balance_wallet_outlined,
        formatProfileCurrency(stats.totalSpent),
        'Tổng chi',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E8), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_dining_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Canteen Membership',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 320) {
                return Wrap(
                  spacing: 0,
                  runSpacing: 14,
                  children: items
                      .map(
                        (item) => SizedBox(
                          width: constraints.maxWidth / 2,
                          child: _StatItem(item: item),
                        ),
                      )
                      .toList(growable: false),
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0)
                      Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(child: _StatItem(item: items[index])),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.item});

  final _StatData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(item.icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
