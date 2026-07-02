enum NotificationFilter { all, offers, activity }

enum NotificationType {
  order,
  payment,
  support,
  voucher,
  reward,
  review,
  system,
  promotion,
  orderReady,
  orderReadyReminder,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.detail,
    this.isUnread = false,
    this.isNew = false,
    this.referenceId = '',
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final String? detail;
  final bool isUnread;
  final bool isNew;
  final String referenceId;

  NotificationFilter get filter {
    switch (type) {
      case NotificationType.promotion:
      case NotificationType.voucher:
        return NotificationFilter.offers;
      case NotificationType.order:
      case NotificationType.orderReady:
      case NotificationType.orderReadyReminder:
      case NotificationType.payment:
      case NotificationType.support:
      case NotificationType.reward:
      case NotificationType.review:
      case NotificationType.system:
        return NotificationFilter.activity;
    }
  }

  AppNotification copyWith({bool? isUnread, bool? isNew, String? referenceId}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      timeLabel: timeLabel,
      detail: detail,
      isUnread: isUnread ?? this.isUnread,
      isNew: isNew ?? this.isNew,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}

const demoNotifications = <AppNotification>[
  AppNotification(
    id: 'offer_welcome',
    type: NotificationType.promotion,
    title: 'Ưu đãi đặc biệt dành cho bạn!',
    message: 'Giảm 20% cho đơn hàng từ 40.000đ',
    detail: 'Áp dụng đến 25/05/2026',
    timeLabel: '5 phút trước',
    isUnread: true,
    isNew: true,
  ),
  AppNotification(
    id: 'offer_lunch',
    type: NotificationType.voucher,
    title: 'Giảm 15% món ăn yêu thích',
    message: 'Giảm 15% khi đặt món trong khung giờ 10:00 - 14:00',
    detail: 'Áp dụng đến 30/05/2026',
    timeLabel: '2 giờ trước',
    isUnread: true,
  ),
  AppNotification(
    id: 'points_added',
    type: NotificationType.reward,
    title: 'Chương trình tích điểm',
    message: 'Bạn vừa được cộng 56 điểm cho đơn hàng SC250522-000123.',
    timeLabel: '1 ngày trước',
  ),
  AppNotification(
    id: 'order_done',
    type: NotificationType.order,
    title: 'Đơn hàng đã hoàn thành',
    message: 'Đơn hàng SC250522-000123 đã hoàn thành. Cảm ơn bạn!',
    timeLabel: '1 ngày trước',
  ),
  AppNotification(
    id: 'order_preparing',
    type: NotificationType.order,
    title: 'Đơn hàng đang được chuẩn bị',
    message: 'Đơn hàng SC250522-000087 đang được chuẩn bị tại quầy A.',
    timeLabel: '1 ngày trước',
    isUnread: true,
  ),
  AppNotification(
    id: 'system_menu',
    type: NotificationType.system,
    title: 'Smart Canteen thông báo',
    message: 'Cập nhật thực đơn mới! Nhiều món ngon đang chờ bạn khám phá.',
    timeLabel: '2 ngày trước',
  ),
];
