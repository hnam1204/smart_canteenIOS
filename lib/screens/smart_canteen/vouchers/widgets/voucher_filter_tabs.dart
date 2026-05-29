import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../voucher_model.dart';

class VoucherFilterTabs extends StatelessWidget {
  const VoucherFilterTabs({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final VoucherFilter selected;
  final int Function(VoucherFilter) countFor;
  final ValueChanged<VoucherFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        key: const ValueKey('voucher-filter-tabs'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: VoucherFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = VoucherFilter.values[index];
          final active = filter == selected;
          return InkWell(
            key: ValueKey('voucher-filter-${filter.name}'),
            onTap: () => onSelected(filter),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    voucherFilterLabel(filter),
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${countFor(filter)}',
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
