import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/firestore_models.dart';

class CategoryFilterItem {
  const CategoryFilterItem({required this.id, required this.label});

  static const String allId = 'all';

  final String id;
  final String label;

  static const all = CategoryFilterItem(id: allId, label: 'Tất cả');
}

List<CategoryFilterItem> categoryFilterItems(
  Iterable<CategoryModel> categories,
) {
  final sorted = categories.toList()
    ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  final byId = HashSet<String>();
  final byName = HashSet<String>();
  final result = <CategoryFilterItem>[CategoryFilterItem.all];
  for (final category in sorted) {
    final id = category.id.trim();
    final name = category.name.trim();
    final normalizedName = name.toLowerCase();
    if (id.isEmpty ||
        name.isEmpty ||
        !byId.add(id) ||
        !byName.add(normalizedName)) {
      continue;
    }
    result.add(CategoryFilterItem(id: id, label: name));
  }
  return result;
}

class CategoryFilterBar extends StatefulWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryFilterItem> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    _scheduleReveal(widget.selectedId);
  }

  @override
  void didUpdateWidget(covariant CategoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId ||
        widget.categories.length != oldWidget.categories.length) {
      _scheduleReveal(widget.selectedId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _select(String id) {
    if (id != widget.selectedId) widget.onSelected(id);
    _scheduleReveal(id);
  }

  void _scheduleReveal(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _keys[id]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories.isEmpty
        ? const [CategoryFilterItem.all]
        : widget.categories;
    return ScrollConfiguration(
      behavior: const _CategoryScrollBehavior(),
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          controller: _scrollController,
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 11),
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryChipItem(
              key: _keys.putIfAbsent(category.id, GlobalKey.new),
              label: category.label,
              selected: category.id == widget.selectedId,
              onTap: () => _select(category.id),
            );
          },
        ),
      ),
    );
  }
}

class CategoryChipItem extends StatelessWidget {
  const CategoryChipItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      scale: selected ? 1.015 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryScrollBehavior extends MaterialScrollBehavior {
  const _CategoryScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
