import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../review_model.dart';

class ReviewImagePicker extends StatelessWidget {
  const ReviewImagePicker({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ReviewImageModel> images;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final image in images)
        _ImagePreview(image: image, onRemove: () => onRemove(image.id)),
      if (images.length < 3) _AddImageButton(onTap: onAdd),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = ((constraints.maxWidth - 18) / 3).clamp(76.0, 110.0);
        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, height: width, child: tile),
          ],
        );
      },
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('add-review-image'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primary,
                size: 27,
              ),
              SizedBox(height: 8),
              Text(
                'Thêm ảnh',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.onRemove});

  final ReviewImageModel image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: image.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Icon(image.icon, color: AppColors.primary, size: 34),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: Material(
            color: AppColors.textPrimary,
            shape: const CircleBorder(),
            child: InkWell(
              key: ValueKey('remove-${image.id}'),
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const SizedBox(
                height: 21,
                width: 21,
                child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
