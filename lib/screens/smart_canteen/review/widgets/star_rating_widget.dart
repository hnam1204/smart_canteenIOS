import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 38,
    this.spacing = 6,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      children: [
        for (var index = 1; index <= 5; index++)
          Semantics(
            button: true,
            selected: index <= rating,
            label: '$index sao',
            child: InkResponse(
              key: ValueKey('rating-star-$index'),
              radius: size,
              onTap: onChanged != null ? () => onChanged!(index) : null,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOutBack,
                scale: index <= rating ? 1.08 : 1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    index <= rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    key: ValueKey(index <= rating),
                    size: size,
                    color: index <= rating
                        ? AppColors.primary
                        : const Color(0xFFD5DAE3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
