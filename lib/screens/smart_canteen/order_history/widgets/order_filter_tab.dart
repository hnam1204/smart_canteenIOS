import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';

class OrderFilterTab extends StatelessWidget {
  const OrderFilterTab({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  final OrderHistoryFilter selectedFilter;
  final ValueChanged<OrderHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        key: const ValueKey('order-filter-list'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: OrderHistoryFilter.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final filter = OrderHistoryFilter.values[index];
          return _FilterItem(
            filter: filter,
            selected: selectedFilter == filter,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final OrderHistoryFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('order-filter-${filter.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Text(
                _label(filter),
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 32 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(OrderHistoryFilter filter) {
    switch (filter) {
      case OrderHistoryFilter.all:
        return 'Tất cả';
      case OrderHistoryFilter.pending:
        return 'Chờ xác nhận';
      case OrderHistoryFilter.preparing:
        return 'Đang chuẩn bị';
      case OrderHistoryFilter.delivering:
        return 'Đang giao';
      case OrderHistoryFilter.completed:
        return 'Đã hoàn thành';
      case OrderHistoryFilter.cancelled:
        return 'Đã hủy';
    }
  }
}
