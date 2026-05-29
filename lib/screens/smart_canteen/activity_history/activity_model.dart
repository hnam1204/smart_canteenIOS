import 'package:flutter/material.dart';

enum ActivityType { all, order, payment, reward, offer, account, system }

enum ActivityStatus { success, processing, failed, cancelled }

enum ActivityPeriod { all, today, last7Days, last30Days, custom }

enum ActivityDayGroup { today, yesterday, thisWeek, thisMonth }

class ActivityFilterModel {
  const ActivityFilterModel({
    this.type = ActivityType.all,
    this.status,
    this.period = ActivityPeriod.all,
  });

  final ActivityType type;
  final ActivityStatus? status;
  final ActivityPeriod period;

  ActivityFilterModel copyWith({
    ActivityType? type,
    ActivityStatus? status,
    bool clearStatus = false,
    ActivityPeriod? period,
  }) {
    return ActivityFilterModel(
      type: type ?? this.type,
      status: clearStatus ? null : (status ?? this.status),
      period: period ?? this.period,
    );
  }
}

class ActivityModel {
  const ActivityModel({
    required this.id,
    required this.type,
    required this.status,
    required this.dayGroup,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.timeLabel,
    required this.occurredAt,
    required this.icon,
    required this.color,
    this.referenceCode,
    this.device,
    this.ipAddress,
    this.hasDetails = true,
  });

  final String id;
  final ActivityType type;
  final ActivityStatus status;
  final ActivityDayGroup dayGroup;
  final String title;
  final String description;
  final String fullDescription;
  final String timeLabel;
  final DateTime occurredAt;
  final IconData icon;
  final Color color;
  final String? referenceCode;
  final String? device;
  final String? ipAddress;
  final bool hasDetails;
}

String activityTypeLabel(ActivityType type) => switch (type) {
  ActivityType.all => 'Tất cả',
  ActivityType.order => 'Đơn hàng',
  ActivityType.payment => 'Thanh toán',
  ActivityType.reward => 'Điểm thưởng',
  ActivityType.offer => 'Ưu đãi',
  ActivityType.account => 'Tài khoản',
  ActivityType.system => 'Hệ thống',
};

String activityStatusLabel(ActivityStatus status) => switch (status) {
  ActivityStatus.success => 'Thành công',
  ActivityStatus.processing => 'Đang xử lý',
  ActivityStatus.failed => 'Thất bại',
  ActivityStatus.cancelled => 'Đã hủy',
};

String activityPeriodLabel(ActivityPeriod period) => switch (period) {
  ActivityPeriod.all => 'Tất cả thời gian',
  ActivityPeriod.today => 'Hôm nay',
  ActivityPeriod.last7Days => '7 ngày gần đây',
  ActivityPeriod.last30Days => '30 ngày gần đây',
  ActivityPeriod.custom => 'Tùy chọn',
};

String activityDayGroupLabel(ActivityDayGroup group) => switch (group) {
  ActivityDayGroup.today => 'Hôm nay',
  ActivityDayGroup.yesterday => 'Hôm qua',
  ActivityDayGroup.thisWeek => 'Tuần này',
  ActivityDayGroup.thisMonth => 'Tháng này',
};

final demoActivities = <ActivityModel>[
  ActivityModel(
    id: 'act_order_1',
    type: ActivityType.order,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.today,
    title: 'Đặt món thành công',
    description: 'Đơn cơm gà xối mỡ đã được ghi nhận.',
    fullDescription:
        'Đơn hàng của bạn đã được gửi tới quầy A và đang chờ nhà bếp chuẩn bị.',
    timeLabel: 'Hôm nay, 12:35',
    occurredAt: DateTime(2026, 5, 25, 12, 35),
    referenceCode: 'SC250525-000126',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFFFF6B00),
  ),
  ActivityModel(
    id: 'act_payment_1',
    type: ActivityType.payment,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.today,
    title: 'Thanh toán thành công',
    description: 'Thanh toán VNPay 56.000đ hoàn tất.',
    fullDescription:
        'Giao dịch thanh toán đã được xác nhận an toàn và hóa đơn điện tử đã sẵn sàng.',
    timeLabel: 'Hôm nay, 12:34',
    occurredAt: DateTime(2026, 5, 25, 12, 34),
    referenceCode: 'PAY-8F21D0',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF2563EB),
  ),
  ActivityModel(
    id: 'act_reward_1',
    type: ActivityType.reward,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.today,
    title: 'Nhận điểm thưởng',
    description: 'Bạn nhận được +120 Smart Canteen Points.',
    fullDescription:
        'Điểm thưởng từ đơn SC250525-000126 đã được cộng vào tài khoản thành viên Vàng.',
    timeLabel: 'Hôm nay, 12:50',
    occurredAt: DateTime(2026, 5, 25, 12, 50),
    referenceCode: 'SC250525-000126',
    icon: Icons.stars_rounded,
    color: Color(0xFFF59E0B),
  ),
  ActivityModel(
    id: 'act_login_1',
    type: ActivityType.account,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.yesterday,
    title: 'Đăng nhập thiết bị mới',
    description: 'Đăng nhập từ iPhone 15 Pro.',
    fullDescription:
        'Một phiên đăng nhập mới đã được xác nhận bằng Firebase Authentication.',
    timeLabel: 'Hôm qua, 18:06',
    occurredAt: DateTime(2026, 5, 24, 18, 6),
    device: 'iPhone 15 Pro - iOS 18',
    ipAddress: '192.168.1.***',
    icon: Icons.phone_iphone_rounded,
    color: Color(0xFF7C3AED),
  ),
  ActivityModel(
    id: 'act_offer_1',
    type: ActivityType.offer,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.yesterday,
    title: 'Sử dụng voucher',
    description: 'Áp dụng mã LUNCH20, tiết kiệm 20.000đ.',
    fullDescription:
        'Mã ưu đãi đã áp dụng thành công cho đơn hàng và không thể sử dụng lại.',
    timeLabel: 'Hôm qua, 12:05',
    occurredAt: DateTime(2026, 5, 24, 12, 5),
    referenceCode: 'LUNCH20',
    icon: Icons.local_activity_outlined,
    color: Color(0xFF7C3AED),
  ),
  ActivityModel(
    id: 'act_cancel_1',
    type: ActivityType.order,
    status: ActivityStatus.cancelled,
    dayGroup: ActivityDayGroup.thisWeek,
    title: 'Hủy đơn hàng',
    description: 'Đơn hàng đã được hủy theo yêu cầu.',
    fullDescription:
        'Yêu cầu hủy đơn được tiếp nhận trước khi bếp bắt đầu chuẩn bị món.',
    timeLabel: '22/05/2026, 10:02',
    occurredAt: DateTime(2026, 5, 22, 10, 2),
    referenceCode: 'SC250522-000102',
    icon: Icons.cancel_outlined,
    color: Color(0xFFDC2626),
  ),
  ActivityModel(
    id: 'act_payment_failed',
    type: ActivityType.payment,
    status: ActivityStatus.failed,
    dayGroup: ActivityDayGroup.thisWeek,
    title: 'Thanh toán thất bại',
    description: 'Giao dịch thẻ không được chấp nhận.',
    fullDescription:
        'Ngân hàng từ chối giao dịch. Vui lòng kiểm tra số dư hoặc chọn phương thức khác.',
    timeLabel: '21/05/2026, 08:42',
    occurredAt: DateTime(2026, 5, 21, 8, 42),
    referenceCode: 'PAY-FAILED-09',
    icon: Icons.credit_card_off_outlined,
    color: Color(0xFFDC2626),
  ),
  ActivityModel(
    id: 'act_reward_exchange',
    type: ActivityType.reward,
    status: ActivityStatus.processing,
    dayGroup: ActivityDayGroup.thisWeek,
    title: 'Đổi điểm thưởng',
    description: 'Đang phát hành voucher Freeship campus.',
    fullDescription:
        'Hệ thống đang xử lý phần thưởng của bạn. Voucher sẽ xuất hiện sau ít phút.',
    timeLabel: '20/05/2026, 09:15',
    occurredAt: DateTime(2026, 5, 20, 9, 15),
    referenceCode: 'RW-FREESHIP-20',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFFF59E0B),
  ),
  ActivityModel(
    id: 'act_profile_update',
    type: ActivityType.account,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.thisMonth,
    title: 'Cập nhật thông tin cá nhân',
    description: 'Số điện thoại liên hệ đã được cập nhật.',
    fullDescription:
        'Thông tin hồ sơ đã thay đổi thành công và đồng bộ với tài khoản của bạn.',
    timeLabel: '14/05/2026, 16:22',
    occurredAt: DateTime(2026, 5, 14, 16, 22),
    device: 'Safari Web - macOS',
    ipAddress: '10.0.0.***',
    icon: Icons.manage_accounts_outlined,
    color: Color(0xFF7C3AED),
  ),
  ActivityModel(
    id: 'act_system',
    type: ActivityType.system,
    status: ActivityStatus.success,
    dayGroup: ActivityDayGroup.thisMonth,
    title: 'Nhận thông báo hệ thống',
    description: 'Smart Canteen có thực đơn mới.',
    fullDescription:
        'Nhiều món mới đã được cập nhật trong menu tuần này. Khám phá ngay hôm nay.',
    timeLabel: '10/05/2026, 08:00',
    occurredAt: DateTime(2026, 5, 10, 8),
    icon: Icons.campaign_outlined,
    color: Color(0xFF2563EB),
  ),
];
