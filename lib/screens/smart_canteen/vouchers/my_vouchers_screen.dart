import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../menu_screen.dart' show MenuScreen;
import '../main_shell_screen.dart';
import '../profile/profile_screen.dart' show ProfileScreen;
import '../reward_points/reward_model.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'voucher_controller.dart';
import 'voucher_history_screen.dart';
import 'voucher_model.dart';
import 'widgets/empty_voucher_state.dart';
import 'widgets/featured_voucher_banner.dart';
import 'widgets/voucher_card.dart';
import 'widgets/voucher_detail_sheet.dart';
import 'widgets/voucher_filter_tabs.dart';
import 'widgets/voucher_summary_card.dart';

class MyVouchersScreen extends StatefulWidget {
  const MyVouchersScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
    this.receivedReward,
  });

  final int cartCount;
  final int notificationCount;
  final RewardItemModel? receivedReward;

  @override
  State<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen> {
  late final VoucherController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = VoucherController(receivedReward: widget.receivedReward)
      ..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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

  Future<void> _copyCode(VoucherModel voucher) async {
    await Clipboard.setData(ClipboardData(text: voucher.code));
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      'Đã sao chép mã ưu đãi.',
      icon: Icons.content_copy_rounded,
      iconColor: AppColors.primary,
    );
  }

  void _useVoucher(VoucherModel voucher) {
    if (!voucher.canUse) {
      return;
    }
    if (!voucher.isEligible) {
      showAppSnackBar(
        context,
        'Đơn hàng chưa đủ điều kiện áp dụng mã này.',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.warning,
      );
      return;
    }
    AppNavigator.push<void>(context, builder: (_) => const MenuScreen());
  }

  void _openDetails(VoucherModel voucher) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => VoucherDetailSheet(
        voucher: voucher,
        onCopy: () => _copyCode(voucher),
        onUse: () {
          Navigator.pop(sheetContext);
          _useVoucher(voucher);
        },
      ),
    );
  }

  void _openHistory() {
    AppNavigator.push<void>(
      context,
      builder: (_) => VoucherHistoryScreen(history: _controller.history),
    );
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
                _VoucherHeader(
                  onBack: _back,
                  onSearch: _searchFocus.requestFocus,
                  onHistory: _openHistory,
                ),
                _VoucherSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _controller.updateSearch,
                  onClear: _clearSearch,
                ),
                const SizedBox(height: 13),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: VoucherFilterTabs(
                    selected: _controller.filter,
                    countFor: _controller.countFor,
                    onSelected: _controller.setFilter,
                  ),
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _controller.loading
                        ? const _VoucherLoading(
                            key: ValueKey('voucher-loading'),
                          )
                        : _controller.hasError
                        ? _VoucherError(
                            key: const ValueKey('voucher-error'),
                            onRetry: _controller.retry,
                          )
                        : _VoucherContent(
                            key: const ValueKey('voucher-content'),
                            controller: _controller,
                            onRefresh: _controller.refresh,
                            onCopy: _copyCode,
                            onDetails: _openDetails,
                            onUse: (voucher) {
                              if (_controller.filter == VoucherFilter.claimable) {
                                _controller.claim(context, voucher.id);
                              } else {
                                _useVoucher(voucher);
                              }
                            },
                            onExplore: () => AppNavigator.push<void>(
                              context,
                              builder: (_) => const MenuScreen(),
                            ),
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

class _VoucherHeader extends StatelessWidget {
  const _VoucherHeader({
    required this.onBack,
    required this.onSearch,
    required this.onHistory,
  });

  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onHistory;

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
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
            const Text(
              'Ưu đãi của tôi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Tìm kiếm',
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded, size: 23),
                  ),
                  IconButton(
                    key: const ValueKey('voucher-history-button'),
                    tooltip: 'Lịch sử sử dụng voucher',
                    onPressed: onHistory,
                    icon: const Icon(Icons.history_rounded, size: 24),
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

class _VoucherSearchBar extends StatefulWidget {
  const _VoucherSearchBar({
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
  State<_VoucherSearchBar> createState() => _VoucherSearchBarState();
}

class _VoucherSearchBarState extends State<_VoucherSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_refresh);
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

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
        key: const ValueKey('voucher-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tên ưu đãi, mã voucher, món ăn',
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
                  key: const ValueKey('clear-voucher-search'),
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

class _VoucherContent extends StatelessWidget {
  const _VoucherContent({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onCopy,
    required this.onDetails,
    required this.onUse,
    required this.onExplore,
  });

  final VoucherController controller;
  final Future<void> Function() onRefresh;
  final ValueChanged<VoucherModel> onCopy;
  final ValueChanged<VoucherModel> onDetails;
  final ValueChanged<VoucherModel> onUse;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final voucherList = controller.visibleVouchers;
    final featured = controller.featuredVoucher;
    final content = <Widget>[
      VoucherSummaryCard(
        total: controller.totalCount,
        expiring: controller.expiringCount,
        used: controller.usedCount,
        saved: controller.totalSaved,
      ),
      if (featured != null) ...[
        const SizedBox(height: 14),
        FeaturedVoucherBanner(voucher: featured, onExplore: onExplore),
      ],
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Text(
          controller.filter == VoucherFilter.claimable
              ? 'Kho ưu đãi hệ thống'
              : 'Voucher của bạn',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      if (voucherList.isEmpty)
        EmptyVoucherState(onExplore: onExplore)
      else
        for (final voucher in voucherList)
          VoucherCard(
            key: ValueKey(voucher.id),
            voucher: voucher,
            onCopy: () => onCopy(voucher),
            onDetails: () => onDetails(voucher),
            onUse: () => onUse(voucher),
            isClaimLabel: controller.filter == VoucherFilter.claimable,
          ),
      const SizedBox(height: 12),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView.builder(
            key: const ValueKey('voucher-content-list'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
            itemCount: content.length + (controller.refreshing ? 1 : 0),
            itemBuilder: (context, index) {
              if (controller.refreshing && index == 0) {
                return const LinearProgressIndicator(
                  color: AppColors.primary,
                  minHeight: 2,
                );
              }
              return content[index - (controller.refreshing ? 1 : 0)];
            },
          ),
        ),
      ),
    );
  }
}

class _VoucherLoading extends StatelessWidget {
  const _VoucherLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
      children: const [
        _Skeleton(height: 105),
        SizedBox(height: 14),
        _Skeleton(height: 84),
        SizedBox(height: 19),
        _Skeleton(height: 218),
        SizedBox(height: 12),
        _Skeleton(height: 218),
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

class _VoucherError extends StatelessWidget {
  const _VoucherError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Không thể tải ưu đãi của bạn.'),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
