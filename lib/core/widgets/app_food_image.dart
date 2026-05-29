import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AppFoodImage extends StatelessWidget {
  const AppFoodImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final path = source?.trim() ?? '';
    final uri = Uri.tryParse(path);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final image = path.isEmpty
        ? _placeholder()
        : isNetwork
        ? CachedNetworkImage(
            imageUrl: path,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, _) => _placeholder(loading: true),
            errorWidget: (_, _, _) => _placeholder(),
          )
        : Image.asset(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _placeholder(),
          );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.textTertiary,
            ),
    );
  }
}
