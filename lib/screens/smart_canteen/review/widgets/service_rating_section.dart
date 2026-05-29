import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../review_model.dart';

class ServiceRatingSection extends StatelessWidget {
  const ServiceRatingSection({
    super.key,
    required this.services,
    required this.ratings,
    this.onChanged,
  });

  final List<ServiceRatingModel> services;
  final Map<String, int> ratings;
  final void Function(String id, int rating)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < services.length; index++) ...[
          _ServiceRatingRow(
            service: services[index],
            rating: ratings[services[index].id] ?? 0,
            onChanged: onChanged != null ? (value) => onChanged!(services[index].id, value) : null,
          ),
          if (index != services.length - 1)
            const Divider(height: 19, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _ServiceRatingRow extends StatelessWidget {
  const _ServiceRatingRow({
    required this.service,
    required this.rating,
    this.onChanged,
  });

  final ServiceRatingModel service;
  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(service.icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            service.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        for (var index = 1; index <= 5; index++)
          InkResponse(
            key: ValueKey('${service.id}-star-$index'),
            radius: 18,
            onTap: onChanged != null ? () => onChanged!(index) : null,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                index <= rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: index <= rating
                    ? AppColors.primary
                    : const Color(0xFFD5DAE3),
                size: 22,
              ),
            ),
          ),
      ],
    );
  }
}
