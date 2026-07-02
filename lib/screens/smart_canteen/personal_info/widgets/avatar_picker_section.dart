import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/colors.dart';

class AvatarPickerSection extends StatelessWidget {
  const AvatarPickerSection({
    super.key,
    required this.fullName,
    required this.email,
    required this.avatarVariant,
    required this.avatarUrl,
    required this.editing,
    required this.onAvatarTap,
  });

  final String fullName;
  final String email;
  final int avatarVariant;
  final String avatarUrl;
  final bool editing;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFFFD9C2), Color(0xFFFFF1E7)],
      [Color(0xFFFFCDA8), Color(0xFFFFE8D8)],
      [Color(0xFFFFE3C9), Color(0xFFFFCFAF)],
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4EC), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: palettes[avatarVariant % palettes.length],
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: AppColors.cardShadow,
                ),
                child: ClipOval(
                  child: avatarUrl.trim().isEmpty
                      ? Icon(
                          avatarVariant == 1
                              ? Icons.face_3_rounded
                              : avatarVariant == 2
                              ? Icons.face_4_rounded
                              : Icons.person_rounded,
                          color: const Color(0xFF7A3E2A),
                          size: 53,
                        )
                      : CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 150,
                          memCacheHeight: 150,
                          placeholder: (context, url) => const Center(
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            avatarVariant == 1
                                ? Icons.face_3_rounded
                                : avatarVariant == 2
                                ? Icons.face_4_rounded
                                : Icons.person_rounded,
                            color: const Color(0xFF7A3E2A),
                            size: 53,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 0,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: const ValueKey('change-personal-avatar'),
                    onTap: onAvatarTap,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      height: 31,
                      width: 31,
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: editing ? AppColors.primarySoft : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              editing
                  ? 'Đang chỉnh sửa hồ sơ'
                  : 'Chạm camera để đổi ảnh đại diện',
              style: TextStyle(
                color: editing ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
