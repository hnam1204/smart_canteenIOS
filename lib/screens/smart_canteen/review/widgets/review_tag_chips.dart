import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../review_model.dart';

class ReviewTagChips extends StatelessWidget {
  const ReviewTagChips({
    super.key,
    required this.tags,
    required this.selectedTags,
    this.onSelected,
  });

  final List<ReviewTagModel> tags;
  final Set<String> selectedTags;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (final tag in tags)
          _ReviewChip(
            tag: tag,
            selected: selectedTags.contains(tag.id),
            onTap: onSelected != null ? () => onSelected!(tag.id) : null,
          ),
      ],
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({
    required this.tag,
    required this.selected,
    this.onTap,
  });

  final ReviewTagModel tag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('review-tag-${tag.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 210),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  tag.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
