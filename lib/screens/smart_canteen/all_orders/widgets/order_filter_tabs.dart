import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';

class OrderFilterTabs extends StatelessWidget {
  const OrderFilterTabs({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final OrderFilter selected;
  final int Function(OrderFilter filter) countFor;
  final ValueChanged<OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        key: const ValueKey('all-orders-filter-tabs'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = OrderFilter.values[index];
          return _FilterChip(
            filter: filter,
            count: countFor(filter),
            selected: selected == filter,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final OrderFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('order-filter-${filter.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _labelFor(filter),
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(OrderFilter filter) {
    return switch (filter) {
      OrderFilter.all => 'Tất cả',
      OrderFilter.pending => 'Chờ xác nhận',
      OrderFilter.preparing => 'Đang chuẩn bị',
      OrderFilter.delivering => 'Đang giao',
      OrderFilter.completed => 'Đã hoàn thành',
      OrderFilter.cancelled => 'Đã hủy',
    };
  }
}
