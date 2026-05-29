import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../notification_model.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _FilterItem(
            label: 'Tất cả',
            value: NotificationFilter.all,
            selected: selectedFilter == NotificationFilter.all,
            onTap: onSelected,
          ),
          _FilterItem(
            label: 'Ưu đãi',
            value: NotificationFilter.offers,
            selected: selectedFilter == NotificationFilter.offers,
            onTap: onSelected,
          ),
          _FilterItem(
            label: 'Hoạt động',
            value: NotificationFilter.activity,
            selected: selectedFilter == NotificationFilter.activity,
            onTap: onSelected,
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final NotificationFilter value;
  final bool selected;
  final ValueChanged<NotificationFilter> onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(value),
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
