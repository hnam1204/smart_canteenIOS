import 'package:flutter/material.dart';

enum MembershipTier { bronze, silver, gold, diamond }

enum RewardHistoryFilter { all, earned, redeemed, expired }

enum RewardHistoryType { earned, redeemed, expiring, expired }

enum RewardStatus { success, processing, expired }

enum RewardType { voucher, freeItem, freeShip, combo }

class RewardPointsModel {
  const RewardPointsModel({
    required this.availablePoints,
    required this.lifetimePoints,
    required this.usedPoints,
    required this.expiringPoints,
    required this.eligibleOrders,
    required this.currentTier,
    required this.pointsToNextTier,
    required this.nextTierProgress,
  });

  final int availablePoints;
  final int lifetimePoints;
  final int usedPoints;
  final int expiringPoints;
  final int eligibleOrders;
  final MembershipTier currentTier;
  final int pointsToNextTier;
  final double nextTierProgress;

  RewardPointsModel copyWith({
    int? availablePoints,
    int? usedPoints,
    int? pointsToNextTier,
    double? nextTierProgress,
  }) {
    return RewardPointsModel(
      availablePoints: availablePoints ?? this.availablePoints,
      lifetimePoints: lifetimePoints,
      usedPoints: usedPoints ?? this.usedPoints,
      expiringPoints: expiringPoints,
      eligibleOrders: eligibleOrders,
      currentTier: currentTier,
      pointsToNextTier: pointsToNextTier ?? this.pointsToNextTier,
      nextTierProgress: nextTierProgress ?? this.nextTierProgress,
    );
  }
}

class MembershipTierModel {
  const MembershipTierModel({
    required this.tier,
    required this.minimumPoints,
    required this.benefit,
    required this.icon,
    required this.colors,
  });

  final MembershipTier tier;
  final int minimumPoints;
  final String benefit;
  final IconData icon;
  final List<Color> colors;
}

class RewardHistoryModel {
  const RewardHistoryModel({
    required this.id,
    required this.type,
    required this.title,
    required this.points,
    required this.timeLabel,
    required this.status,
    this.orderId,
  });

  final String id;
  final RewardHistoryType type;
  final String title;
  final int points;
  final String timeLabel;
  final RewardStatus status;
  final String? orderId;
}

class RewardItemModel {
  const RewardItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.condition,
    required this.pointsRequired,
    required this.expiryLabel,
    required this.remainingQuantity,
    required this.icon,
    required this.colors,
  });

  final String id;
  final RewardType type;
  final String title;
  final String description;
  final String condition;
  final int pointsRequired;
  final String expiryLabel;
  final int remainingQuantity;
  final IconData icon;
  final List<Color> colors;
}

String membershipTierLabel(MembershipTier tier) => switch (tier) {
  MembershipTier.bronze => 'Member',
  MembershipTier.silver => 'Bạc',
  MembershipTier.gold => 'Vàng',
  MembershipTier.diamond => 'Kim cương',
};

String rewardStatusLabel(RewardStatus status) => switch (status) {
  RewardStatus.success => 'Thành công',
  RewardStatus.processing => 'Đang xử lý',
  RewardStatus.expired => 'Hết hạn',
};

String formatRewardPoints(int points) {
  final value = points.abs().toString();
  final output = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    if (index > 0 && (value.length - index) % 3 == 0) output.write('.');
    output.write(value[index]);
  }
  return output.toString();
}

const demoRewardPoints = RewardPointsModel(
  availablePoints: 1250,
  lifetimePoints: 3780,
  usedPoints: 2050,
  expiringPoints: 180,
  eligibleOrders: 27,
  currentTier: MembershipTier.gold,
  pointsToNextTier: 750,
  nextTierProgress: 0.63,
);

const demoMembershipTiers = [
  MembershipTierModel(
    tier: MembershipTier.bronze,
    minimumPoints: 0,
    benefit: 'Tích 1 điểm / 1.000đ',
    icon: Icons.workspace_premium_outlined,
    colors: [Color(0xFFB87333), Color(0xFFD69A64)],
  ),
  MembershipTierModel(
    tier: MembershipTier.silver,
    minimumPoints: 500,
    benefit: 'Freeship mỗi tháng',
    icon: Icons.military_tech_outlined,
    colors: [Color(0xFF94A3B8), Color(0xFFD7DEE9)],
  ),
  MembershipTierModel(
    tier: MembershipTier.gold,
    minimumPoints: 1000,
    benefit: 'Ưu đãi 10% độc quyền',
    icon: Icons.stars_rounded,
    colors: [Color(0xFFF59E0B), Color(0xFFFACC15)],
  ),
  MembershipTierModel(
    tier: MembershipTier.diamond,
    minimumPoints: 2000,
    benefit: 'Quà sinh nhật cao cấp',
    icon: Icons.diamond_outlined,
    colors: [Color(0xFF7C3AED), Color(0xFFB794F4)],
  ),
];

const demoRewardHistory = [
  RewardHistoryModel(
    id: 'reward_history_1',
    type: RewardHistoryType.earned,
    title: 'Tích điểm từ đơn hàng',
    points: 120,
    timeLabel: 'Hôm nay, 12:35',
    status: RewardStatus.success,
    orderId: 'SC250525-000126',
  ),
  RewardHistoryModel(
    id: 'reward_history_2',
    type: RewardHistoryType.redeemed,
    title: 'Đổi voucher giảm giá 20.000đ',
    points: -250,
    timeLabel: '24/05/2026, 09:20',
    status: RewardStatus.success,
  ),
  RewardHistoryModel(
    id: 'reward_history_3',
    type: RewardHistoryType.expiring,
    title: 'Điểm sắp hết hạn',
    points: -180,
    timeLabel: 'Hết hạn ngày 31/05/2026',
    status: RewardStatus.processing,
  ),
  RewardHistoryModel(
    id: 'reward_history_4',
    type: RewardHistoryType.earned,
    title: 'Tích điểm từ đơn hàng',
    points: 85,
    timeLabel: '22/05/2026, 11:05',
    status: RewardStatus.success,
    orderId: 'SC250522-000123',
  ),
  RewardHistoryModel(
    id: 'reward_history_5',
    type: RewardHistoryType.expired,
    title: 'Điểm đã hết hạn',
    points: -40,
    timeLabel: '15/05/2026, 23:59',
    status: RewardStatus.expired,
  ),
];

const demoRewardItems = [
  RewardItemModel(
    id: 'reward_voucher',
    type: RewardType.voucher,
    title: 'Voucher 30.000đ',
    description: 'Giảm trực tiếp cho đơn từ 80.000đ.',
    condition: 'Áp dụng cho tất cả món, một lần sử dụng.',
    pointsRequired: 300,
    expiryLabel: '30 ngày sau khi đổi',
    remainingQuantity: 24,
    icon: Icons.local_activity_outlined,
    colors: [Color(0xFFFFE3C8), Color(0xFFFFF5EB)],
  ),
  RewardItemModel(
    id: 'reward_food',
    type: RewardType.freeItem,
    title: 'Tặng Trà tắc',
    description: 'Đổi một ly trà tắc size M miễn phí.',
    condition: 'Dùng cùng một món chính bất kỳ.',
    pointsRequired: 420,
    expiryLabel: '14 ngày sau khi đổi',
    remainingQuantity: 8,
    icon: Icons.local_cafe_outlined,
    colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
  ),
  RewardItemModel(
    id: 'reward_ship',
    type: RewardType.freeShip,
    title: 'Freeship campus',
    description: 'Miễn phí giao món trong khuôn viên.',
    condition: 'Đơn hàng tối thiểu 45.000đ.',
    pointsRequired: 650,
    expiryLabel: '21 ngày sau khi đổi',
    remainingQuantity: 15,
    icon: Icons.delivery_dining_outlined,
    colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
  ),
  RewardItemModel(
    id: 'reward_combo',
    type: RewardType.combo,
    title: 'Combo Gold đặc biệt',
    description: 'Cơm gà + nước uống với giá ưu đãi.',
    condition: 'Chỉ dành cho thành viên Vàng trở lên.',
    pointsRequired: 1500,
    expiryLabel: '07 ngày sau khi đổi',
    remainingQuantity: 5,
    icon: Icons.restaurant_menu_rounded,
    colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
  ),
];
