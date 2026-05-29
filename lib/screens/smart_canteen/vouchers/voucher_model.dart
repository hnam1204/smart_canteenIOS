import 'package:flutter/material.dart';

enum VoucherStatus { available, expiringSoon, used, expired }

enum VoucherType { percentDiscount, amountDiscount, freeShipping, freeItem }

enum VoucherFilter { claimable, mine, used, expired }

class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.title,
    required this.code,
    required this.type,
    required this.valueLabel,
    required this.description,
    required this.condition,
    required this.validFrom,
    required this.validUntil,
    required this.applicableFoods,
    required this.remainingUses,
    required this.status,
    required this.icon,
    required this.expiryProgress,
    this.isEligible = true,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String code;
  final VoucherType type;
  final String valueLabel;
  final String description;
  final String condition;
  final String validFrom;
  final String validUntil;
  final List<String> applicableFoods;
  final int remainingUses;
  final VoucherStatus status;
  final IconData icon;
  final double expiryProgress;
  final bool isEligible;
  final bool isFeatured;

  bool get canUse =>
      status == VoucherStatus.available || status == VoucherStatus.expiringSoon;
}

class VoucherHistoryModel {
  const VoucherHistoryModel({
    required this.id,
    required this.title,
    required this.code,
    required this.usedAt,
    required this.savedAmount,
  });

  final String id;
  final String title;
  final String code;
  final String usedAt;
  final int savedAmount;
}

String voucherStatusLabel(VoucherStatus status) => switch (status) {
  VoucherStatus.available => 'Có thể dùng',
  VoucherStatus.expiringSoon => 'Sắp hết hạn',
  VoucherStatus.used => 'Đã dùng',
  VoucherStatus.expired => 'Hết hạn',
};

String voucherFilterLabel(VoucherFilter filter) => switch (filter) {
  VoucherFilter.claimable => 'Có thể nhận',
  VoucherFilter.mine => 'Voucher của tôi',
  VoucherFilter.used => 'Đã dùng',
  VoucherFilter.expired => 'Hết hạn',
};

String formatVoucherMoney(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      output.write('.');
    }
    output.write(digits[index]);
  }
  return '$outputđ';
}

const demoVouchers = [
  VoucherModel(
    id: 'voucher_featured',
    title: 'Ưu đãi bữa trưa - giảm 20%',
    code: 'FRESH20',
    type: VoucherType.percentDiscount,
    valueLabel: 'Giảm 20%',
    description: 'Giảm tối đa 30.000đ cho đơn ăn trưa.',
    condition: 'Đơn tối thiểu 60.000đ, áp dụng một lần.',
    validFrom: '20/05/2026',
    validUntil: '31/05/2026',
    applicableFoods: ['Cơm gà xối mỡ', 'Cơm sườn nướng', 'Bún bò Huế'],
    remainingUses: 1,
    status: VoucherStatus.available,
    icon: Icons.percent_rounded,
    expiryProgress: 0.74,
    isFeatured: true,
  ),
  VoucherModel(
    id: 'voucher_lunch',
    title: 'Giảm 15% món yêu thích',
    code: 'LUNCH15',
    type: VoucherType.percentDiscount,
    valueLabel: 'Giảm 15%',
    description: 'Voucher dành cho combo trưa được chọn.',
    condition: 'Đơn tối thiểu 90.000đ.',
    validFrom: '22/05/2026',
    validUntil: '28/05/2026',
    applicableFoods: ['Combo Gold đặc biệt', 'Mì xào hải sản'],
    remainingUses: 1,
    status: VoucherStatus.expiringSoon,
    icon: Icons.timer_outlined,
    expiryProgress: 0.92,
    isEligible: false,
  ),
  VoucherModel(
    id: 'voucher_freeship',
    title: 'Freeship trong campus',
    code: 'FREESHIP',
    type: VoucherType.freeShipping,
    valueLabel: 'Freeship',
    description: 'Miễn phí giao món trong khuôn viên.',
    condition: 'Đơn tối thiểu 45.000đ.',
    validFrom: '15/05/2026',
    validUntil: '15/06/2026',
    applicableFoods: ['Tất cả món ăn'],
    remainingUses: 2,
    status: VoucherStatus.available,
    icon: Icons.delivery_dining_outlined,
    expiryProgress: 0.38,
  ),
  VoucherModel(
    id: 'voucher_used',
    title: 'Giảm trực tiếp 30.000đ',
    code: 'SAVE30',
    type: VoucherType.amountDiscount,
    valueLabel: '-30.000đ',
    description: 'Đã áp dụng cho đơn SC250520-000045.',
    condition: 'Đơn tối thiểu 80.000đ.',
    validFrom: '01/05/2026',
    validUntil: '24/05/2026',
    applicableFoods: ['Tất cả món ăn'],
    remainingUses: 0,
    status: VoucherStatus.used,
    icon: Icons.local_activity_outlined,
    expiryProgress: 1,
  ),
  VoucherModel(
    id: 'voucher_expired',
    title: 'Tặng Trà tắc size M',
    code: 'DRINKFREE',
    type: VoucherType.freeItem,
    valueLabel: 'Tặng món',
    description: 'Tặng nước uống khi mua một món chính.',
    condition: 'Không áp dụng cùng voucher khác.',
    validFrom: '01/05/2026',
    validUntil: '18/05/2026',
    applicableFoods: ['Trà tắc'],
    remainingUses: 0,
    status: VoucherStatus.expired,
    icon: Icons.local_cafe_outlined,
    expiryProgress: 1,
  ),
];

const demoVoucherHistory = [
  VoucherHistoryModel(
    id: 'used_1',
    title: 'Giảm trực tiếp 30.000đ',
    code: 'SAVE30',
    usedAt: '20/05/2026, 12:25',
    savedAmount: 30000,
  ),
  VoucherHistoryModel(
    id: 'used_2',
    title: 'Giảm 15% bữa sáng',
    code: 'BREAKFAST15',
    usedAt: '10/05/2026, 08:10',
    savedAmount: 18000,
  ),
];
