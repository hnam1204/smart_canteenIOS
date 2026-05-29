import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../reward_model.dart';

class RewardExchangeCard extends StatelessWidget {
  const RewardExchangeCard({
    super.key,
    required this.reward,
    required this.enabled,
    required this.onTap,
  });

  final RewardItemModel reward;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('reward-item-${reward.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: reward.colors),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      reward.icon,
                      color: AppColors.primary,
                      size: 23,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatRewardPoints(reward.pointsRequired)}đ',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                reward.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                reward.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.3,
                  fontSize: 10.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: FilledButton(
                  key: ValueKey('exchange-${reward.id}'),
                  onPressed: enabled ? onTap : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.surfaceSoft,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    enabled ? 'Đổi ngay' : 'Chưa đủ điểm',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

class RewardDetailSheet extends StatelessWidget {
  const RewardDetailSheet({
    super.key,
    required this.reward,
    required this.points,
    required this.canExchange,
    required this.onExchange,
  });

  final RewardItemModel reward;
  final int points;
  final bool canExchange;
  final VoidCallback onExchange;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            11,
            20,
            MediaQuery.viewPaddingOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: reward.colors),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      reward.icon,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatRewardPoints(reward.pointsRequired)} điểm',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _DetailLine(title: 'Mô tả', value: reward.description),
                      _DetailLine(title: 'Điều kiện', value: reward.condition),
                      _DetailLine(title: 'Hiệu lực', value: reward.expiryLabel),
                      _DetailLine(
                        title: 'Số lượng còn lại',
                        value: '${reward.remainingQuantity} phần thưởng',
                      ),
                      _DetailLine(
                        title: 'Điểm hiện có',
                        value: '${formatRewardPoints(points)} điểm',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton(
                  key: const ValueKey('confirm-reward-exchange'),
                  onPressed: canExchange ? onExchange : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    canExchange ? 'Xác nhận đổi' : 'Bạn chưa đủ điểm',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class ExchangeSuccessDialog extends StatelessWidget {
  const ExchangeSuccessDialog({
    super.key,
    required this.reward,
    required this.remainingPoints,
    required this.onViewOffers,
  });

  final RewardItemModel reward;
  final int remainingPoints;
  final VoidCallback onViewOffers;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Đổi thưởng thành công',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${reward.title} đã được thêm vào ưu đãi của bạn.\nCòn ${formatRewardPoints(remainingPoints)} điểm.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1.45,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 47),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('view-reward-offers'),
                    onPressed: onViewOffers,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 47),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Xem ưu đãi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
