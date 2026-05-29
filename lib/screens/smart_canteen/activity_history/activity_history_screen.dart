import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../all_orders/all_orders_screen.dart';
import '../menu_screen.dart' show MenuScreen;
import '../main_shell_screen.dart';
import '../profile/profile_screen.dart' show ProfileScreen;
import '../reward_points/reward_points_screen.dart';
import '../vouchers/my_vouchers_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'activity_history_controller.dart';
import 'activity_model.dart';
import 'widgets/activity_filter_tabs.dart';
import 'widgets/activity_sheets.dart';
import 'widgets/activity_summary_card.dart';
import 'widgets/activity_timeline.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late final ActivityHistoryController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = ActivityHistoryController()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _replace(Widget screen) {
    AppNavigator.replace<void>(context, builder: (_) => screen);
  }

  void _back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    _replace(ProfileScreen(cartCount: widget.cartCount));
  }

  void _onNavigationTap(int index) {
    _replace(MainShellScreen(initialIndex: index));
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityFilterSheet(
        initialFilter: _controller.filter,
        onApply: _controller.applyAdvancedFilter,
        onReset: _controller.resetFilters,
      ),
    );
  }

  Future<void> _openDetails(ActivityModel activity) async {
    final openDestination = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ActivityDetailSheet(
        activity: activity,
        onActionTap: () {
          Navigator.pop(sheetContext, true);
        },
      ),
    );
    if (openDestination == true && mounted) {
      _handleActivityAction(activity);
    }
  }

  void _handleActivityAction(ActivityModel activity) {
    switch (activity.type) {
      case ActivityType.order:
        AppNavigator.push<void>(
          context,
          builder: (_) => AllOrdersScreen(cartCount: widget.cartCount),
        );
        return;
      case ActivityType.reward:
        AppNavigator.push<void>(
          context,
          builder: (_) => RewardPointsScreen(
            cartCount: widget.cartCount,
            notificationCount: widget.notificationCount,
          ),
        );
        return;
      case ActivityType.account:
        AppNavigator.push<void>(
          context,
          builder: (_) => ProfileScreen(cartCount: widget.cartCount),
        );
        return;
      case ActivityType.payment:
        showAppSnackBar(
          context,
          'Chi tiết giao dịch ${activity.referenceCode ?? ''} đã được tải.',
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF2563EB),
        );
        return;
      case ActivityType.offer:
        AppNavigator.push<void>(
          context,
          builder: (_) => MyVouchersScreen(
            cartCount: widget.cartCount,
            notificationCount: widget.notificationCount,
          ),
        );
        return;
      case ActivityType.system:
      case ActivityType.all:
        AppNavigator.push<void>(context, builder: (_) => const MenuScreen());
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  onBackTap: _back,
                  onSearchTap: _searchFocusNode.requestFocus,
                  onFilterTap: _openFilters,
                ),
                _ActivitySearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _controller.updateSearch,
                  onClear: _clearSearch,
                ),
                const SizedBox(height: 13),
                ActivityFilterTabs(
                  selected: _controller.filter.type,
                  countFor: _controller.countFor,
                  onSelected: _controller.setType,
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _controller.loading
                        ? const _ActivityLoading(
                            key: ValueKey('activity-loading'),
                          )
                        : _controller.hasError
                        ? _ActivityError(
                            key: const ValueKey('activity-error'),
                            onRetry: _controller.retry,
                          )
                        : _ActivityContent(
                            key: const ValueKey('activity-content'),
                            controller: _controller,
                            onRefresh: _controller.refresh,
                            onDetailsTap: _openDetails,
                            onExploreTap: () =>
                                _handleActivityAction(demoActivities.last),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.onBackTap,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Quay lại',
                onPressed: onBackTap,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
            const Text(
              'Lịch sử hoạt động',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Tìm kiếm',
                    onPressed: onSearchTap,
                    icon: const Icon(Icons.search_rounded, size: 23),
                  ),
                  IconButton(
                    key: const ValueKey('open-activity-filters'),
                    tooltip: 'Lọc hoạt động',
                    onPressed: onFilterTap,
                    icon: const Icon(Icons.tune_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySearchBar extends StatefulWidget {
  const _ActivitySearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_ActivitySearchBar> createState() => _ActivitySearchBarState();
}

class _ActivitySearchBarState extends State<_ActivitySearchBar> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_update);
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_update);
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.focusNode.hasFocus
              ? AppColors.primary
              : AppColors.divider,
          width: widget.focusNode.hasFocus ? 1.4 : 1,
        ),
        boxShadow: widget.focusNode.hasFocus ? AppColors.cardShadow : null,
      ),
      child: TextField(
        key: const ValueKey('activity-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Nội dung, mã đơn, thời gian',
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  key: const ValueKey('clear-activity-search'),
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onDetailsTap,
    required this.onExploreTap,
  });

  final ActivityHistoryController controller;
  final Future<void> Function() onRefresh;
  final ValueChanged<ActivityModel> onDetailsTap;
  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ActivitySummaryCard(
        total: controller.totalActivities,
        orders: controller.orderedCount,
        logins: controller.loginCount,
        rewards: controller.rewardCount,
      ),
      if (controller.visibleActivities.isEmpty)
        EmptyActivityState(onExploreTap: onExploreTap)
      else
        ActivityTimelineList(
          groups: controller.groupedActivities,
          onDetailsTap: onDetailsTap,
        ),
      const SizedBox(height: 12),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.builder(
            key: const ValueKey('activity-content-list'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
            itemCount: children.length + (controller.refreshing ? 1 : 0),
            itemBuilder: (context, index) {
              if (controller.refreshing && index == 0) {
                return const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                );
              }
              final adjustedIndex = index - (controller.refreshing ? 1 : 0);
              final child = children[adjustedIndex];
              if (adjustedIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: child,
                );
              }
              return child;
            },
          ),
        ),
      ),
    );
  }
}

class EmptyActivityState extends StatelessWidget {
  const EmptyActivityState({super.key, required this.onExploreTap});
  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 34),
      child: Container(
        padding: const EdgeInsets.all(27),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 52,
              color: AppColors.primary,
            ),
            const SizedBox(height: 13),
            const Text(
              'Chưa có hoạt động nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            const Text(
              'Các hoạt động của bạn sẽ hiển thị tại đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 17),
            FilledButton(
              onPressed: onExploreTap,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Khám phá món ăn'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
      children: const [
        _Skeleton(height: 92),
        SizedBox(height: 20),
        _Skeleton(height: 120),
        SizedBox(height: 12),
        _Skeleton(height: 120),
        SizedBox(height: 12),
        _Skeleton(height: 120),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
    );
  }
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.textTertiary,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text('Không thể tải lịch sử hoạt động.'),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
