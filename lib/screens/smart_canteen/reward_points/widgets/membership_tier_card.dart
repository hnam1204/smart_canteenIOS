import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../reward_model.dart';

class MembershipTierSection extends StatelessWidget {
  const MembershipTierSection({
    super.key,
    required this.tiers,
    required this.currentTier,
  });

  final List<MembershipTierModel> tiers;
  final MembershipTier currentTier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Hạng thành viên', trailing: 'Quyền lợi'),
        const SizedBox(height: 11),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 2),
            physics: const BouncingScrollPhysics(),
            itemCount: tiers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tier = tiers[index];
              return MembershipTierCard(
                tier: tier,
                active: tier.tier == currentTier,
              );
            },
          ),
        ),
      ],
    );
  }
}

class MembershipTierCard extends StatelessWidget {
  const MembershipTierCard({
    super.key,
    required this.tier,
    required this.active,
  });

  final MembershipTierModel tier;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      width: 158,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFFBF5) : AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.divider,
          width: active ? 1.3 : 1,
        ),
        boxShadow: active ? AppColors.cardShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tier.colors),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(tier.icon, color: Colors.white, size: 19),
                ),
              ),
              const Spacer(),
              if (active)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            membershipTierLabel(tier.tier),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Từ ${formatRewardPoints(tier.minimumPoints)} điểm',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tier.benefit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          trailing,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.primary, fontSize: 12),
        ),
      ],
    );
  }
}
