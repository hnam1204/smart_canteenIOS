import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../help_center_model.dart';

class FAQCategoryTabs extends StatelessWidget {
  const FAQCategoryTabs({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final HelpCategory selected;
  final int Function(HelpCategory category) countFor;
  final ValueChanged<HelpCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: const ValueKey('faq-category-tabs'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: HelpCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = HelpCategory.values[index];
          final selectedCategory = category == selected;
          return InkWell(
            key: ValueKey('faq-category-${category.name}'),
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: selectedCategory ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selectedCategory
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    helpCategoryLabel(category),
                    style: TextStyle(
                      color: selectedCategory
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: selectedCategory
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selectedCategory
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${countFor(category)}',
                      style: TextStyle(
                        color: selectedCategory
                            ? Colors.white
                            : AppColors.primary,
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

class FAQAccordionList extends StatefulWidget {
  const FAQAccordionList({super.key, required this.items});

  final List<FAQModel> items;

  @override
  State<FAQAccordionList> createState() => _FAQAccordionListState();
}

class _FAQAccordionListState extends State<FAQAccordionList> {
  String? _expandedId;

  @override
  void didUpdateWidget(covariant FAQAccordionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.items.any((item) => item.id == _expandedId)) {
      _expandedId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final faq in widget.items)
          _FAQTile(
            faq: faq,
            expanded: _expandedId == faq.id,
            onTap: () => setState(
              () => _expandedId = _expandedId == faq.id ? null : faq.id,
            ),
          ),
      ],
    );
  }
}

class _FAQTile extends StatelessWidget {
  const _FAQTile({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  final FAQModel faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: expanded ? const Color(0xFFFFDCC3) : AppColors.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('faq-${faq.id}'),
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Text(
                      faq.answer,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
