import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderHistoryStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.foreground,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _ChipStyle _style(OrderHistoryStatus status) {
    switch (status) {
      case OrderHistoryStatus.pending:
        return const _ChipStyle(
          label: 'Chờ xác nhận',
          foreground: AppColors.primary,
          background: AppColors.primarySoft,
        );
      case OrderHistoryStatus.preparing:
        return const _ChipStyle(
          label: 'Đang chuẩn bị',
          foreground: Color(0xFF1976D2),
          background: Color(0xFFEAF4FF),
        );
      case OrderHistoryStatus.delivering:
        return const _ChipStyle(
          label: 'Đang giao',
          foreground: Color(0xFF7B3FE4),
          background: Color(0xFFF2EAFE),
        );
      case OrderHistoryStatus.delivered:
        return const _ChipStyle(
          label: 'Đã giao',
          foreground: AppColors.success,
          background: Color(0xFFEAF8EE),
        );
      case OrderHistoryStatus.completed:
        return const _ChipStyle(
          label: 'Hoàn thành',
          foreground: AppColors.success,
          background: Color(0xFFEAF8EE),
        );
      case OrderHistoryStatus.cancelled:
        return const _ChipStyle(
          label: 'Đã hủy',
          foreground: AppColors.error,
          background: Color(0xFFFFEEEE),
        );
    }
  }
}

class _ChipStyle {
  const _ChipStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
