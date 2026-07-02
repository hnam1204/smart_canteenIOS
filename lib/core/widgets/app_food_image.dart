import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/number_safety.dart';

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
  static final Map<String, Future<String?>> _storageUrlCache = {};

  @override
  Widget build(BuildContext context) {
    final layoutWidth = _safeDimension(width);
    final layoutHeight = _safeDimension(height);
    final path = source?.trim() ?? '';
    final image = path.isEmpty
        ? _placeholder()
        : _isNetwork(path)
        ? _networkImage(path)
        : _isFirebaseStorageUri(path)
        ? FutureBuilder<String?>(
            future: _storageDownloadUrl(path),
            builder: (context, snapshot) {
              final url = snapshot.data;
              if (url != null && url.isNotEmpty) {
                return _networkImage(url);
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return _placeholder(loading: true);
              }
              return _placeholder();
            },
          )
        : Image.asset(
            path,
            width: layoutWidth,
            height: layoutHeight,
            fit: fit,
            errorBuilder: (_, _, _) => _placeholder(),
          );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  bool _isNetwork(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _isFirebaseStorageUri(String path) => path.startsWith('gs://');

  Widget _networkImage(String url) {
    final layoutWidth = _safeDimension(width);
    final layoutHeight = _safeDimension(height);
    return CachedNetworkImage(
      imageUrl: url,
      width: layoutWidth,
      height: layoutHeight,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => _placeholder(loading: true),
      errorWidget: (_, _, error) {
        debugPrint('AppFoodImage failed to load "$url": $error');
        return _placeholder();
      },
      memCacheWidth: _cacheExtent(width),
      memCacheHeight: _cacheExtent(height),
    );
  }

  Future<String?> _storageDownloadUrl(String storageUri) {
    return _storageUrlCache.putIfAbsent(storageUri, () async {
      if (Firebase.apps.isEmpty) return null;
      try {
        return await FirebaseStorage.instance
            .refFromURL(storageUri)
            .getDownloadURL();
      } catch (error) {
        debugPrint(
          'AppFoodImage failed to resolve Firebase Storage URI '
          '"$storageUri": $error',
        );
        return null;
      }
    });
  }

  Widget _placeholder({bool loading = false}) {
    final layoutWidth = _safeDimension(width);
    final layoutHeight = _safeDimension(height);
    return Container(
      width: layoutWidth,
      height: layoutHeight,
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

  double? _safeDimension(double? value) {
    if (value == null) return null;
    final safeValue = safeFiniteDouble(value, fallback: -1);
    return safeValue >= 0 ? safeValue : null;
  }

  int? _cacheExtent(double? value) {
    if (value == null) return null;
    final safeValue = safeFiniteDouble(value, fallback: -1);
    if (safeValue <= 0) return null;
    return safeValue.round().clamp(1, 4096).toInt();
  }
}
