import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class ActivitySummaryCard extends StatelessWidget {
  const ActivitySummaryCard({
    super.key,
    required this.total,
    required this.orders,
    required this.logins,
    required this.rewards,
  });

  final int total;
  final int orders;
  final int logins;
  final int rewards;

  @override
  Widget build(BuildContext context) {
    final data = [
      _Stat(Icons.history_rounded, '$total', 'Hoạt động'),
      _Stat(Icons.shopping_bag_outlined, '$orders', 'Đơn đặt'),
      _Stat(Icons.login_rounded, '$logins', 'Đăng nhập'),
      _Stat(Icons.stars_rounded, '$rewards', 'Nhận điểm'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF9847)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 330) {
            return Wrap(
              runSpacing: 12,
              children: [
                for (final stat in data)
                  SizedBox(
                    width: constraints.maxWidth / 2,
                    child: _StatView(stat: stat),
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < data.length; index++) ...[
                Expanded(child: _StatView(stat: data[index])),
                if (index < data.length - 1)
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Stat {
  const _Stat(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
}

class _StatView extends StatelessWidget {
  const _StatView({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(stat.icon, color: Colors.white, size: 19),
        const SizedBox(height: 5),
        Text(
          stat.value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: const TextStyle(color: Color(0xFFFFF0E7), fontSize: 10.5),
        ),
      ],
    );
  }
}
