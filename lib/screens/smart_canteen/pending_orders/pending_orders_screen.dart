import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../main_shell_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'order_model.dart';
import 'pending_orders_controller.dart';
import 'widgets/cancel_order_dialog.dart';
import 'widgets/empty_pending_state.dart';
import 'widgets/pending_order_card.dart';
import 'widgets/pending_order_detail_sheet.dart';
import 'widgets/pending_status_banner.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  late final PendingOrdersController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = PendingOrdersController()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    AppNavigator.replace<void>(
      context,
      builder: (_) => MainShellScreen(initialIndex: index),
    );
  }

  void _back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    _onBottomNavTap(4);
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CancelOrderDialog(order: order),
    );
    if (confirmed != true || !mounted) return;
    final cancelled = _controller.cancelOrder(order.id);
    if (!cancelled) {
      showAppSnackBar(
        context,
        'Yêu cầu hủy đơn cần được xác nhận bởi hệ thống hỗ trợ.',
        icon: Icons.schedule_rounded,
        iconColor: AppColors.primary,
      );
      return;
    }
    showAppSnackBar(
      context,
      'Đã hủy đơn ${order.id}.',
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
    );
  }

  void _openDetails(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PendingOrderDetailSheet(
        order: order,
        waitingTime: _controller.waitingFor(order),
        onCancelTap: () {
          Navigator.pop(sheetContext);
          _cancelOrder(order);
        },
      ),
    );
  }

  void _contactCounter(OrderModel order) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Liên hệ ${order.pickupCounter}'),
        content: const Text(
          'Hotline căn tin: 1900 1234\nNhân viên sẽ hỗ trợ trạng thái đơn của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showAppSnackBar(
                this.context,
                'Đang kết nối với quầy nhận món.',
                icon: Icons.call_outlined,
                iconColor: AppColors.primary,
              );
            },
            icon: const Icon(Icons.call_outlined, size: 18),
            label: const Text('Gọi quầy'),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _WaitingFilterSheet(
        selected: _controller.filter,
        countFor: _controller.countFor,
        onSelected: (filter) {
          Navigator.pop(context);
          _controller.setFilter(filter);
        },
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                onBackTap: _back,
                onSearchTap: _searchFocusNode.requestFocus,
                onFilterTap: _showFilters,
              ),
              const PendingStatusBanner(),
              _SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _controller.updateSearch,
                onClear: _clearSearch,
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
        bottomNavigationBar: CanteenBottomNavBar(
          selectedIndex: -1,
          cartCount: widget.cartCount,
          notificationCount: widget.notificationCount,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.loading) return const _PendingLoading();
    if (_controller.hasError) {
      return _PendingError(onRetry: _controller.retry);
    }
    final orders = _controller.visibleOrders;
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 365,
              child: EmptyPendingState(onOrderNowTap: () => _onBottomNavTap(1)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        key: const ValueKey('pending-orders-list'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return PendingOrderCard(
            key: ValueKey(order.id),
            order: order,
            waitingTime: _controller.waitingFor(order),
            onCancelTap: () => _cancelOrder(order),
            onDetailsTap: () => _openDetails(order),
            onContactTap: () => _contactCounter(order),
          );
        },
      ),
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
    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Quay lại',
              onPressed: onBackTap,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
            ),
          ),
          const Text(
            'Chờ xác nhận',
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
                  key: const ValueKey('focus-pending-search'),
                  tooltip: 'Tìm kiếm',
                  onPressed: onSearchTap,
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  key: const ValueKey('open-pending-filter'),
                  tooltip: 'Bộ lọc',
                  onPressed: onFilterTap,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
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
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

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
        key: const ValueKey('pending-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm theo mã đơn hàng hoặc tên món',
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('clear-pending-search'),
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _PendingLoading extends StatelessWidget {
  const _PendingLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        height: 265,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }
}

class _PendingError extends StatelessWidget {
  const _PendingError({required this.onRetry});

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
          const SizedBox(height: 13),
          const Text('Không thể tải đơn hàng.'),
          const SizedBox(height: 13),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _WaitingFilterSheet extends StatelessWidget {
  const _WaitingFilterSheet({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final WaitingFilter selected;
  final int Function(WaitingFilter) countFor;
  final ValueChanged<WaitingFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Thời gian chờ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            for (final filter in WaitingFilter.values)
              ListTile(
                key: ValueKey('pending-filter-${filter.name}'),
                onTap: () => onSelected(filter),
                title: Text(_label(filter)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${countFor(filter)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      selected == filter
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected == filter
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _label(WaitingFilter filter) {
    return switch (filter) {
      WaitingFilter.all => 'Tất cả đang chờ',
      WaitingFilter.normal => 'Dưới 10 phút',
      WaitingFilter.delayed => 'Quá 10 phút',
    };
  }
}
