import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../voucher_model.dart';

class VoucherSummaryCard extends StatelessWidget {
  const VoucherSummaryCard({
    super.key,
    required this.total,
    required this.expiring,
    required this.used,
    required this.saved,
  });

  final int total;
  final int expiring;
  final int used;
  final int saved;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(Icons.confirmation_number_outlined, '$total', 'Hiện có'),
      _SummaryItem(Icons.schedule_rounded, '$expiring', 'Sắp hết hạn'),
      _SummaryItem(Icons.check_circle_outline_rounded, '$used', 'Đã dùng'),
      _SummaryItem(
        Icons.savings_outlined,
        formatVoucherMoney(saved),
        'Đã tiết kiệm',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Wrap(
              spacing: 8,
              runSpacing: 11,
              children: [
                for (final item in items)
                  SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: _SummaryMetric(item: item),
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _SummaryMetric(item: items[index])),
                if (index < items.length - 1)
                  Container(
                    height: 48,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(item.icon, color: Colors.white, size: 20),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFFEEE1), fontSize: 10.5),
        ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}
