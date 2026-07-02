import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../services/auth_service.dart';
import '../activity_history/activity_history_screen.dart';
import '../all_orders/all_orders_screen.dart';
import '../all_orders/order_model.dart' show OrderFilter;
import '../delivered_orders/delivered_orders_screen.dart';
import '../delivering_orders/delivering_orders_screen.dart';
import '../help_center/help_center_screen.dart';
import '../main_shell_screen.dart';
import '../pending_orders/pending_orders_screen.dart';
import '../personal_info/personal_info_screen.dart';
import '../preparing_orders/preparing_orders_screen.dart';
import '../reward_points/reward_points_screen.dart';
import '../vouchers/my_vouchers_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'profile_controller.dart';
import 'user_model.dart';
import 'widgets/order_status_widget.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.cartCount,
    this.embedded = false,
    this.onTabSelected,
  });

  final int? cartCount;
  final bool embedded;
  final ValueChanged<int>? onTabSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replace(Widget screen) {
    AppNavigator.replace<void>(context, builder: (_) => screen);
  }

  void _onNavigationTap(int index, UserProfile profile) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }
    _replace(MainShellScreen(initialIndex: index));
  }

  void _openNotifications(UserProfile profile) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(3);
      return;
    }
    _replace(const MainShellScreen(initialIndex: 3));
  }

  void _changeAvatar() {
    _controller.updateAvatar();
    showAppSnackBar(context, 'Ảnh đại diện đã được cập nhật.');
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ProfileSettingsSheet(),
    );
  }

  void _openProfileDetails(UserProfile profile) {
    AppNavigator.push<void>(
      context,
      builder: (_) => PersonalInfoScreen(
        cartCount: widget.cartCount ?? profile.cartCount,
        notificationCount: profile.unreadNotifications,
      ),
    );
  }

  void _openMenuAction(ProfileMenuOption option, UserProfile profile) {
    if (option.action == ProfileMenuAction.personalInformation) {
      AppNavigator.push<void>(
        context,
        builder: (_) => PersonalInfoScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
          notificationCount: profile.unreadNotifications,
        ),
      );
      return;
    }
    if (option.action == ProfileMenuAction.points) {
      AppNavigator.push<void>(
        context,
        builder: (_) => RewardPointsScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
          notificationCount: profile.unreadNotifications,
        ),
      );
      return;
    }
    if (option.action == ProfileMenuAction.offers) {
      AppNavigator.push<void>(
        context,
        builder: (_) => MyVouchersScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
          notificationCount: profile.unreadNotifications,
        ),
      );
      return;
    }
    if (option.action == ProfileMenuAction.activity) {
      AppNavigator.push<void>(
        context,
        builder: (_) => ActivityHistoryScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
          notificationCount: profile.unreadNotifications,
        ),
      );
      return;
    }
    if (option.action == ProfileMenuAction.support) {
      AppNavigator.push<void>(
        context,
        builder: (_) => HelpCenterScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
          notificationCount: profile.unreadNotifications,
        ),
      );
      return;
    }
    _openFeature(
      title: option.title,
      description: _descriptionFor(option.action),
      icon: _iconFor(option.action),
    );
  }

  void _openStatus(OrderStatusSummary status, UserProfile profile) {
    if (status.kind == OrderStatusKind.pending) {
      AppNavigator.push<void>(
        context,
        builder: (_) => PendingOrdersScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
        ),
      );
      return;
    }
    if (status.kind == OrderStatusKind.preparing) {
      AppNavigator.push<void>(
        context,
        builder: (_) => PreparingOrdersScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
        ),
      );
      return;
    }
    if (status.kind == OrderStatusKind.delivering) {
      AppNavigator.push<void>(
        context,
        builder: (_) => DeliveringOrdersScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
        ),
      );
      return;
    }
    if (status.kind == OrderStatusKind.completed) {
      AppNavigator.push<void>(
        context,
        builder: (_) => DeliveredOrdersScreen(
          cartCount: widget.cartCount ?? profile.cartCount,
        ),
      );
      return;
    }
    AppNavigator.push<void>(
      context,
      builder: (_) => AllOrdersScreen(
        initialFilter: _filterForStatus(status.kind),
        cartCount: widget.cartCount ?? profile.cartCount,
      ),
    );
  }

  OrderFilter _filterForStatus(OrderStatusKind kind) {
    return switch (kind) {
      OrderStatusKind.all => OrderFilter.all,
      OrderStatusKind.pending => OrderFilter.pending,
      OrderStatusKind.preparing => OrderFilter.preparing,
      OrderStatusKind.delivering => OrderFilter.delivering,
      OrderStatusKind.completed => OrderFilter.completed,
      OrderStatusKind.cancelled => OrderFilter.cancelled,
    };
  }

  void _openFeature({
    required String title,
    required String description,
    required IconData icon,
  }) {
    AppNavigator.push<void>(
      context,
      builder: (_) => _ProfileDestinationScreen(
        title: title,
        description: description,
        icon: icon,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục đặt món và sử dụng điểm thưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await AuthService().signOut();
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Đã đăng xuất khỏi Smart Canteen.',
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
    );
    AppNavigator.pushNamedAndRemoveUntil<void>(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final profile =
            _controller.profile ??
            const UserProfile(
              id: '',
              fullName: '',
              phone: '',
              email: '',
              points: 0,
              cartCount: 0,
              unreadNotifications: 0,
              avatarVariant: 0,
              orderStatuses: [],
              menuOptions: [],
            );
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ProfileHeader(
                  notificationCount: profile.unreadNotifications,
                  onSettingsTap: _openSettings,
                  onNotificationsTap: () => _openNotifications(profile),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _controller.loading
                        ? const _ProfileLoading(key: ValueKey('loading'))
                        : _ProfileContent(
                            key: const ValueKey('profile-content'),
                            profile: profile,
                            refreshing: _controller.refreshing,
                            onRefresh: _controller.refresh,
                            onAvatarTap: _changeAvatar,
                            onProfileTap: () => _openProfileDetails(profile),
                            onPointsTap: () => _openMenuAction(
                              const ProfileMenuOption(
                                action: ProfileMenuAction.points,
                                title: 'Điểm thưởng',
                              ),
                              profile,
                            ),
                            onStatusTap: (status) =>
                                _openStatus(status, profile),
                            onViewOrdersTap: () => _openStatus(
                              profile.orderStatuses.first,
                              profile,
                            ),
                            onMenuTap: (option) =>
                                _openMenuAction(option, profile),
                            onLogoutTap: _confirmLogout,
                          ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: widget.embedded
              ? null
              : CanteenBottomNavBar(
                  selectedIndex: 4,
                  cartCount: widget.cartCount ?? profile.cartCount,
                  notificationCount: profile.unreadNotifications,
                  onTap: (index) => _onNavigationTap(index, profile),
                ),
        );
      },
    );
  }

  IconData _iconFor(ProfileMenuAction action) {
    switch (action) {
      case ProfileMenuAction.personalInformation:
        return Icons.person_outline_rounded;
      case ProfileMenuAction.addresses:
        return Icons.location_on_outlined;
      case ProfileMenuAction.offers:
        return Icons.sell_outlined;
      case ProfileMenuAction.points:
        return Icons.stars_outlined;
      case ProfileMenuAction.activity:
        return Icons.history_rounded;
      case ProfileMenuAction.support:
        return Icons.help_outline_rounded;
    }
  }

  String _descriptionFor(ProfileMenuAction action) {
    switch (action) {
      case ProfileMenuAction.personalInformation:
        return 'Quản lý hồ sơ, số điện thoại và email liên hệ của bạn.';
      case ProfileMenuAction.addresses:
        return 'Lưu và chỉnh sửa các địa điểm nhận món quen thuộc.';
      case ProfileMenuAction.offers:
        return 'Ưu đãi dành riêng cho tài khoản của bạn sẽ hiển thị tại đây.';
      case ProfileMenuAction.points:
        return 'Bạn có 1.250 điểm Smart Canteen để đổi quà và mã giảm giá.';
      case ProfileMenuAction.activity:
        return 'Theo dõi hoạt động nhận điểm, đánh giá và ưu đãi đã dùng.';
      case ProfileMenuAction.support:
        return 'Liên hệ hỗ trợ và xem câu hỏi thường gặp về đơn hàng.';
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    super.key,
    required this.profile,
    required this.refreshing,
    required this.onRefresh,
    required this.onAvatarTap,
    required this.onProfileTap,
    required this.onPointsTap,
    required this.onStatusTap,
    required this.onViewOrdersTap,
    required this.onMenuTap,
    required this.onLogoutTap,
  });

  final UserProfile profile;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback onAvatarTap;
  final VoidCallback onProfileTap;
  final VoidCallback onPointsTap;
  final ValueChanged<OrderStatusSummary> onStatusTap;
  final VoidCallback onViewOrdersTap;
  final ValueChanged<ProfileMenuOption> onMenuTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView(
            key: const ValueKey('profile-content-list'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              if (refreshing) const LinearProgressIndicator(minHeight: 2),
              _ProfileCard(
                profile: profile,
                onAvatarTap: onAvatarTap,
                onTap: onProfileTap,
                onPointsTap: onPointsTap,
              ),
              const SizedBox(height: 18),
              OrderStatusSection(
                statuses: profile.orderStatuses,
                onStatusTap: onStatusTap,
                onViewAllTap: onViewOrdersTap,
              ),
              const SizedBox(height: 18),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < profile.menuOptions.length;
                      index++
                    )
                      ProfileMenuItem(
                        icon: _menuIcon(profile.menuOptions[index].action),
                        title: profile.menuOptions[index].title,
                        showDivider: index != profile.menuOptions.length - 1,
                        onTap: () => onMenuTap(profile.menuOptions[index]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _LogoutButton(onPressed: onLogoutTap),
            ],
          ),
        ),
      ),
    );
  }

  IconData _menuIcon(ProfileMenuAction action) {
    switch (action) {
      case ProfileMenuAction.personalInformation:
        return Icons.person_outline_rounded;
      case ProfileMenuAction.addresses:
        return Icons.location_on_outlined;
      case ProfileMenuAction.offers:
        return Icons.sell_outlined;
      case ProfileMenuAction.points:
        return Icons.stars_outlined;
      case ProfileMenuAction.activity:
        return Icons.history_rounded;
      case ProfileMenuAction.support:
        return Icons.help_outline_rounded;
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onAvatarTap,
    required this.onTap,
    required this.onPointsTap,
  });

  final UserProfile profile;
  final VoidCallback onAvatarTap;
  final VoidCallback onTap;
  final VoidCallback onPointsTap;

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: onTap,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5ED), Color(0xFFFFFBF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE5D2)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _Avatar(
                      variant: profile.avatarVariant,
                      avatarUrl: profile.avatarUrl,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -3,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onAvatarTap,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 25,
                            height: 25,
                            child: Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName.isEmpty
                            ? 'Chưa cập nhật'
                            : profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProfileLine(
                        icon: Icons.phone_outlined,
                        text: profile.phone.isEmpty
                            ? 'Chưa cập nhật'
                            : profile.phone,
                      ),
                      const SizedBox(height: 6),
                      _ProfileLine(
                        icon: Icons.mail_outline_rounded,
                        text: profile.email.isEmpty
                            ? 'Chưa cập nhật'
                            : profile.email,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 15),
            _PointsCard(points: profile.points, onTap: onPointsTap),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.variant, this.avatarUrl = ''});

  final int variant;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFFFD9C2), Color(0xFFFFF0E5)],
      [Color(0xFFFFC59E), Color(0xFFFFEADA)],
      [Color(0xFFFFE0CB), Color(0xFFFFCFAE)],
    ];

    if (avatarUrl.isNotEmpty) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 69,
        height: 69,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFE5D2), width: 2),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            memCacheWidth: 150,
            memCacheHeight: 150,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    palettes[variant % palettes.length][0],
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) =>
                _PlaceholderAvatar(variant: variant),
          ),
        ),
      );
    }

    return _PlaceholderAvatar(variant: variant);
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFFFD9C2), Color(0xFFFFF0E5)],
      [Color(0xFFFFC59E), Color(0xFFFFEADA)],
      [Color(0xFFFFE0CB), Color(0xFFFFCFAE)],
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 69,
      height: 69,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: palettes[variant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        variant == 1
            ? Icons.face_3_rounded
            : variant == 2
            ? Icons.face_4_rounded
            : Icons.person_rounded,
        color: const Color(0xFF7A3E2A),
        size: 40,
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points, required this.onTap});

  final int points;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFE8D9)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Canteen Points',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(points)} điểm',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Xem chi tiết',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNumber(int value) {
    final digits = value.toString();
    final output = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
      output.write(digits[index]);
    }
    return output.toString();
  }
}

class _PressableCard extends StatefulWidget {
  const _PressableCard({
    required this.onTap,
    required this.decoration,
    required this.child,
  });

  final VoidCallback onTap;
  final Decoration decoration;
  final Widget child;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      scale: _pressed ? 0.992 : 1,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: DecoratedBox(decoration: widget.decoration, child: widget.child),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('profile-logout-button'),
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded, size: 19),
      label: const Text('Đăng xuất'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: Color(0xFFFFD7D5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 20),
      children: const [
        _Skeleton(height: 198),
        SizedBox(height: 15),
        _Skeleton(height: 137),
        SizedBox(height: 14),
        _Skeleton(height: 360),
        SizedBox(height: 14),
        _Skeleton(height: 88),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            height: 16,
            width: 126,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsSheet extends StatefulWidget {
  const _ProfileSettingsSheet();

  @override
  State<_ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<_ProfileSettingsSheet> {
  bool _biometrics = true;
  bool _notifyOrder = true;
  bool _notifyPromotion = true;
  bool _notifySupport = true;
  bool _notifySystem = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final uid = _currentUid;
    if (uid == null) {
      setState(() => _loadingPrefs = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final settings = data['notificationSettings'] as Map<String, dynamic>? ?? {};
      setState(() {
        _notifyOrder = settings['order'] as bool? ?? data['notifyOrder'] as bool? ?? true;
        _notifyPromotion = settings['promotion'] as bool? ?? data['notifyPromotion'] as bool? ?? true;
        _notifySupport = settings['support'] as bool? ?? data['notifySupport'] as bool? ?? true;
        _notifySystem = settings['system'] as bool? ?? data['notifySystem'] as bool? ?? true;
        _loadingPrefs = false;
      });
    } catch (_) {
      setState(() => _loadingPrefs = false);
    }
  }

  String? get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _updatePref(String key, bool value) async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'notificationSettings': {
          key: value,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently ignore preference sync errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkMode = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Cài đặt tài khoản',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile.adaptive(
            value: _biometrics,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primarySoft,
            title: const Text('Xác thực sinh trắc học'),
            subtitle: const Text('Bảo vệ thanh toán nhanh và an toàn'),
            onChanged: (value) => setState(() => _biometrics = value),
          ),
          SwitchListTile.adaptive(
            value: darkMode,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primarySoft,
            title: const Text('Chế độ tối'),
            subtitle: const Text('Tự động theo thiết bị khi khả dụng'),
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cài đặt thông báo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_loadingPrefs)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else ...[
            SwitchListTile.adaptive(
              value: _notifyOrder,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Đơn hàng'),
              subtitle: const Text('Cập nhật trạng thái đơn hàng'),
              onChanged: (value) {
                setState(() => _notifyOrder = value);
                _updatePref('order', value);
              },
            ),
            SwitchListTile.adaptive(
              value: _notifyPromotion,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Khuyến mãi'),
              subtitle: const Text('Ưu đãi và chương trình khuyến mãi'),
              onChanged: (value) {
                setState(() => _notifyPromotion = value);
                _updatePref('promotion', value);
              },
            ),
            SwitchListTile.adaptive(
              value: _notifySupport,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Hỗ trợ'),
              subtitle: const Text('Phản hồi từ nhân viên hỗ trợ'),
              onChanged: (value) {
                setState(() => _notifySupport = value);
                _updatePref('support', value);
              },
            ),
            SwitchListTile.adaptive(
              value: _notifySystem,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              title: const Text('Hệ thống'),
              subtitle: const Text('Thông báo cập nhật từ hệ thống'),
              onChanged: (value) {
                setState(() => _notifySystem = value);
                _updatePref('system', value);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileDestinationScreen extends StatelessWidget {
  const _ProfileDestinationScreen({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
