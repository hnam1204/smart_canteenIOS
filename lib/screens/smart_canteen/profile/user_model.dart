enum OrderStatusKind {
  all,
  pending,
  preparing,
  delivering,
  completed,
  cancelled,
}

enum ProfileMenuAction {
  personalInformation,
  addresses,
  offers,
  points,
  activity,
  support,
}

class OrderStatusSummary {
  const OrderStatusSummary({
    required this.kind,
    required this.label,
    required this.count,
  });

  final OrderStatusKind kind;
  final String label;
  final int count;
}

class ProfileMenuOption {
  const ProfileMenuOption({required this.action, required this.title});

  final ProfileMenuAction action;
  final String title;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.points,
    required this.cartCount,
    required this.unreadNotifications,
    required this.avatarVariant,
    required this.orderStatuses,
    required this.menuOptions,
    this.avatarUrl = '',
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final int points;
  final int cartCount;
  final int unreadNotifications;
  final int avatarVariant;
  final String avatarUrl;
  final List<OrderStatusSummary> orderStatuses;
  final List<ProfileMenuOption> menuOptions;

  UserProfile copyWith({
    int? points,
    int? unreadNotifications,
    int? avatarVariant,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      points: points ?? this.points,
      cartCount: cartCount,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      avatarVariant: avatarVariant ?? this.avatarVariant,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      orderStatuses: orderStatuses,
      menuOptions: menuOptions,
    );
  }
}

const demoUserProfile = UserProfile(
  id: 'sc_user_001',
  fullName: 'Nguyễn Thảo Vy',
  phone: '0901 234 567',
  email: 'thaovy.nguyen@gmail.com',
  points: 1250,
  cartCount: 3,
  unreadNotifications: 3,
  avatarVariant: 0,
  avatarUrl: '',
  orderStatuses: [
    OrderStatusSummary(
      kind: OrderStatusKind.all,
      label: 'Tất cả đơn',
      count: 3,
    ),
    OrderStatusSummary(
      kind: OrderStatusKind.pending,
      label: 'Chờ xác nhận',
      count: 1,
    ),
    OrderStatusSummary(
      kind: OrderStatusKind.preparing,
      label: 'Đang chuẩn bị',
      count: 1,
    ),
    OrderStatusSummary(
      kind: OrderStatusKind.delivering,
      label: 'Đang giao',
      count: 0,
    ),
    OrderStatusSummary(
      kind: OrderStatusKind.completed,
      label: 'Đã hoàn thành',
      count: 12,
    ),
    OrderStatusSummary(
      kind: OrderStatusKind.cancelled,
      label: 'Đã hủy',
      count: 0,
    ),
  ],
  menuOptions: [
    ProfileMenuOption(
      action: ProfileMenuAction.personalInformation,
      title: 'Thông tin cá nhân',
    ),
    ProfileMenuOption(
      action: ProfileMenuAction.offers,
      title: 'Ưu đãi của tôi',
    ),
    ProfileMenuOption(action: ProfileMenuAction.points, title: 'Điểm thưởng'),
    ProfileMenuOption(
      action: ProfileMenuAction.activity,
      title: 'Lịch sử hoạt động',
    ),
    ProfileMenuOption(
      action: ProfileMenuAction.support,
      title: 'Trung tâm trợ giúp',
    ),
  ],
);
