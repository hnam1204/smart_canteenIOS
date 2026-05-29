import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../help_center_model.dart';

class QuickSupportGrid extends StatelessWidget {
  const QuickSupportGrid({
    super.key,
    required this.actions,
    required this.onTap,
  });

  final List<HelpActionModel> actions;
  final ValueChanged<QuickSupportAction> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: _ActionCard(
                  action: action,
                  onTap: () => onTap(action.action),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final HelpActionModel action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        key: ValueKey('support-action-${action.action.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Container(
                height: 39,
                width: 39,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 21),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
