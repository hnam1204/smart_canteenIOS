import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../all_orders_controller.dart';
import '../order_model.dart';

class AllOrderStatusChip extends StatelessWidget {
  const AllOrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(
          color: style.foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ChipStyle _styleFor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => const _ChipStyle(
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      OrderStatus.preparing => const _ChipStyle(
        foreground: Color(0xFF1976D2),
        background: Color(0xFFEAF4FF),
      ),
      OrderStatus.delivering => const _ChipStyle(
        foreground: Color(0xFF16A34A),
        background: Color(0xFFECFDF5),
      ),
      OrderStatus.delivered => const _ChipStyle(
        foreground: AppColors.success,
        background: Color(0xFFEAF8EF),
      ),
      OrderStatus.completed => const _ChipStyle(
        foreground: AppColors.success,
        background: Color(0xFFEAF8EF),
      ),
      OrderStatus.cancelled => const _ChipStyle(
        foreground: AppColors.error,
        background: Color(0xFFFFEEEE),
      ),
    };
  }
}

class _ChipStyle {
  const _ChipStyle({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}
