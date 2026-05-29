import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../voucher_model.dart';
import 'voucher_card.dart';

class VoucherDetailSheet extends StatelessWidget {
  const VoucherDetailSheet({
    super.key,
    required this.voucher,
    required this.onCopy,
    required this.onUse,
  });

  final VoucherModel voucher;
  final VoidCallback onCopy;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
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
            MediaQuery.viewPaddingOf(context).bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Chi tiết ưu đãi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(voucher.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        VoucherStatusChip(status: voucher.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        voucher.code,
                        key: const ValueKey('voucher-detail-code'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('detail-copy-voucher'),
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      label: const Text('Sao chép'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _DetailLine('Giá trị', voucher.valueLabel),
                      _DetailLine('Mô tả', voucher.description),
                      _DetailLine('Điều kiện', voucher.condition),
                      _DetailLine('Bắt đầu', voucher.validFrom),
                      _DetailLine('Hết hạn', voucher.validUntil),
                      _DetailLine(
                        'Lượt còn lại',
                        '${voucher.remainingUses} lượt sử dụng',
                      ),
                      _DetailLine(
                        'Món áp dụng',
                        voucher.applicableFoods.join(', '),
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
                  key: const ValueKey('detail-use-voucher'),
                  onPressed: voucher.canUse ? onUse : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Dùng ngay',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.title, this.value);

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
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
