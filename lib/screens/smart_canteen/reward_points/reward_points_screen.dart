import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../menu_screen.dart' show MenuScreen;
import '../main_shell_screen.dart';
import '../profile/profile_screen.dart' show ProfileScreen;
import '../vouchers/my_vouchers_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'reward_history_screen.dart';
import 'reward_model.dart';
import 'reward_points_controller.dart';
import 'widgets/membership_tier_card.dart';
import 'widgets/reward_exchange_widgets.dart';
import 'widgets/reward_hero_card.dart';
import 'widgets/reward_history_widgets.dart';
import 'widgets/reward_summary_card.dart';

class RewardPointsScreen extends StatefulWidget {
  const RewardPointsScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<RewardPointsScreen> createState() => _RewardPointsScreenState();
}

class _RewardPointsScreenState extends State<RewardPointsScreen> {
  late final RewardPointsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RewardPointsController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    _replace(ProfileScreen(cartCount: widget.cartCount));
  }

  void _replace(Widget screen) {
    AppNavigator.replace<void>(context, builder: (_) => screen);
  }

  void _onNavigationTap(int index) {
    _replace(MainShellScreen(initialIndex: index));
  }

  void _openHistory() {
    AppNavigator.push<void>(
      context,
      builder: (_) => RewardHistoryScreen(history: _controller.history),
    );
  }

  void _orderNow() {
    AppNavigator.push<void>(context, builder: (_) => const MenuScreen());
  }

  void _openReward(RewardItemModel reward) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RewardDetailSheet(
        reward: reward,
        points: _controller.points.availablePoints,
        canExchange: _controller.canExchange(reward),
        onExchange: () {
          Navigator.pop(sheetContext);
          _exchangeReward(reward);
        },
      ),
    );
  }

  Future<void> _exchangeReward(RewardItemModel reward) async {
    final success = await _controller.exchangeReward(context, reward);
    if (success && mounted) {
      _showReceivedReward(reward);
    }
  }

  void _showReceivedReward(RewardItemModel reward) {
    AppNavigator.push<void>(
      context,
      builder: (_) => MyVouchersScreen(
        cartCount: widget.cartCount,
        notificationCount: widget.notificationCount,
        receivedReward: reward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _RewardHeader(onBack: _back, onHistory: _openHistory),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _controller.loading
                        ? const _RewardLoading(key: ValueKey('reward-loading'))
                        : _controller.error
                        ? _RewardError(
                            key: const ValueKey('reward-error'),
                            onRetry: _controller.retry,
                          )
                        : _RewardContent(
                            key: const ValueKey('reward-content'),
                            controller: _controller,
                            onRefresh: _controller.refresh,
                            onRewardTap: _openReward,
                            onOrderNow: _orderNow,
                          ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CanteenBottomNavBar(
            selectedIndex: 4,
            cartCount: widget.cartCount,
            notificationCount: widget.notificationCount,
            onTap: _onNavigationTap,
          ),
        );
      },
    );
  }
}

class _RewardHeader extends StatelessWidget {
  const _RewardHeader({required this.onBack, required this.onHistory});

  final VoidCallback onBack;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      child: SizedBox(
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                IconButton(
                  key: const ValueKey('reward-history-button'),
                  tooltip: 'Lịch sử điểm',
                  onPressed: onHistory,
                  icon: const Icon(Icons.history_rounded, size: 25),
                ),
              ],
            ),
            const Text(
              'Điểm thưởng',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardContent extends StatelessWidget {
  const _RewardContent({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onRewardTap,
    required this.onOrderNow,
  });

  final RewardPointsController controller;
  final Future<void> Function() onRefresh;
  final ValueChanged<RewardItemModel> onRewardTap;
  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    final history = controller.visibleHistory;
    final hasVouchers = controller.rewards.isNotEmpty;
    final widgets = <Widget>[
      RewardHeroCard(points: controller.points),
      const SizedBox(height: 21),
      MembershipTierSection(
        tiers: controller.tiers,
        currentTier: controller.points.currentTier,
      ),
      const SizedBox(height: 18),
      RewardSummaryCard(points: controller.points),
      const SizedBox(height: 20),
      // Chỉ hiện phần Đổi quà nếu có voucher khả dụng
      if (hasVouchers) ...[
        const _SectionTitle(title: 'Đổi quà', trailing: 'Dành cho bạn'),
        const SizedBox(height: 11),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.rewards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final reward = controller.rewards[index];
              return RewardExchangeCard(
                reward: reward,
                enabled: controller.canExchange(reward),
                onTap: () => onRewardTap(reward),
              );
            },
          ),
        ),
        const SizedBox(height: 21),
      ],
      const _SectionTitle(title: 'Lịch sử điểm', trailing: 'Gần đây'),
      const SizedBox(height: 11),
      RewardHistoryTabs(
        selected: controller.filter,
        countFor: controller.countFor,
        onSelected: controller.setFilter,
      ),
      const SizedBox(height: 13),
      // Nếu history stream lỗi: hiện inline error, không crash cả trang
      if (controller.historyError)
        _HistoryErrorState(onRetry: controller.retry)
      else if (history.isEmpty)
        EmptyRewardState(onOrderNow: onOrderNow)
      else
        for (final entry in history)
          RewardHistoryItem(key: ValueKey(entry.id), history: entry),
      const SizedBox(height: 12),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.builder(
            key: const ValueKey('reward-content-list'),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: widgets.length + (controller.refreshing ? 1 : 0),
            itemBuilder: (context, index) {
              if (controller.refreshing && index == 0) {
                return const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                );
              }
              return widgets[index - (controller.refreshing ? 1 : 0)];
            },
          ),
        ),
      ),
    );
  }
}

class EmptyRewardState extends StatelessWidget {
  const EmptyRewardState({super.key, required this.onOrderNow});

  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        children: [
          const Icon(Icons.toll_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 11),
          const Text(
            'Chưa có điểm thưởng',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đặt món để bắt đầu tích điểm',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 17),
          FilledButton(
            onPressed: onOrderNow,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Đặt món ngay'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
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
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          trailing,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _RewardLoading extends StatelessWidget {
  const _RewardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      children: const [
        _Skeleton(height: 206),
        SizedBox(height: 20),
        _Skeleton(height: 130),
        SizedBox(height: 17),
        _Skeleton(height: 85),
        SizedBox(height: 20),
        _Skeleton(height: 190),
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
    );
  }
}

class _RewardError extends StatelessWidget {
  const _RewardError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text('Không thể tải điểm thưởng'),
          const SizedBox(height: 15),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

/// Inline widget chỉ hiển thị trong phần lịch sử khi stream lỗi.
/// Không ảnh hưởng phần còn lại của màn hình.
class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.history_toggle_off_rounded,
              color: AppColors.textTertiary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không thể tải lịch sử điểm',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Kiểm tra kết nối và thử lại',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
