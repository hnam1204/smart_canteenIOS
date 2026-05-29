import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../../../../models/firestore_models.dart';

class VoucherBottomSheet extends StatelessWidget {
  const VoucherBottomSheet({
    super.key,
    required this.vouchers,
    required this.subtotal,
    required this.selectedVoucherId,
    required this.onApply,
    required this.onRemove,
  });

  final List<VoucherModel> vouchers;
  final int subtotal;
  final String? selectedVoucherId;
  final ValueChanged<VoucherModel> onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chọn ưu đãi',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selectedVoucherId != null)
                  TextButton(
                    onPressed: onRemove,
                    child: const Text('Bỏ áp dụng'),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            if (vouchers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 34),
                child: Column(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 45,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 13),
                    Text(
                      'Chưa có voucher phù hợp với giỏ hàng',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vouchers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 11),
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    return VoucherCard(
                      voucher: voucher,
                      selected: voucher.id == selectedVoucherId,
                      onApply: () => onApply(voucher),
                      onCopy: () async {
                        await Clipboard.setData(
                          ClipboardData(text: voucher.code),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép mã ưu đãi'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VoucherCard extends StatelessWidget {
  const VoucherCard({
    super.key,
    required this.voucher,
    required this.selected,
    required this.onApply,
    required this.onCopy,
  });

  final VoucherModel voucher;
  final bool selected;
  final VoidCallback onApply;
  final VoidCallback onCopy;

  String get _benefit => switch (voucher.discountType.toLowerCase()) {
    'percent' => 'Giảm ${voucher.discountValue}%',
    'shipping' || 'freeship' || 'free_shipping' => 'Miễn phí dịch vụ',
    _ => 'Giảm ${_money(voucher.discountValue)}',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
        boxShadow: selected ? AppColors.cardShadow : null,
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_benefit - Đơn từ ${_money(voucher.minOrderAmount)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.only(top: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: Text(voucher.code),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(66, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(selected ? 'Đã chọn' : 'Dùng'),
          ),
        ],
      ),
    );
  }
}

String _money(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return '$outputđ';
}
