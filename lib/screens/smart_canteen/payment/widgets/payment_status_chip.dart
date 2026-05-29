import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../payment_model.dart';

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      PaymentStatus.pending => (
        'Chờ thanh toán',
        AppColors.primary,
        AppColors.primarySoft,
      ),
      PaymentStatus.paid => (
        'Đã thanh toán',
        AppColors.success,
        const Color(0xFFECFDF5),
      ),
      PaymentStatus.expired => (
        'Hết hạn',
        AppColors.error,
        const Color(0xFFFEF2F2),
      ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
