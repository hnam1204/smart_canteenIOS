import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../main_shell_screen.dart';
import '../qr_pickup/order_model.dart' as pickup;
import '../qr_pickup/qr_pickup_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'order_model.dart';
import 'preparing_orders_controller.dart';
import 'widgets/contact_counter_dialog.dart';
import 'widgets/empty_preparing_state.dart';
import 'widgets/preparation_timeline.dart';
import 'widgets/preparing_order_card.dart';
import 'widgets/preparing_order_detail_sheet.dart';
import 'widgets/preparing_status_banner.dart';

class PreparingOrdersScreen extends StatefulWidget {
  const PreparingOrdersScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<PreparingOrdersScreen> createState() => _PreparingOrdersScreenState();
}

class _PreparingOrdersScreenState extends State<PreparingOrdersScreen> {
  late final PreparingOrdersController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = PreparingOrdersController()..load();
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

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
  }

  void _openDetails(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PreparingOrderDetailSheet(order: order),
    );
  }

  void _track(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrackingSheet(order: order),
    );
  }

  void _contactCounter(OrderModel order) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ContactCounterDialog(
        order: order,
        onCallTap: () {
          Navigator.pop(dialogContext);
          showAppSnackBar(
            context,
            'Đang kết nối ${order.pickupCounter}.',
            icon: Icons.call_outlined,
            iconColor: preparingBlue,
          );
        },
      ),
    );
  }

  void _openQr(OrderModel order) {
    AppNavigator.push<void>(
      context,
      builder: (_) => QRPickupScreen(
        orderId: order.id,
        previewOrder: _asPickupOrder(order),
      ),
    );
  }

  pickup.OrderModel _asPickupOrder(OrderModel order) {
    return pickup.OrderModel(
      id: order.id,
      placedAt: order.orderedAt,
      readyAt: 'Sẵn sàng',
      pickupCounter: order.pickupCounter,
      pickupDescription: order.items.first.name,
      paymentStatus: order.paymentMethod == PaymentMethod.cash
          ? 'unpaid'
          : 'pending',
      paymentMethod: order.paymentMethod == PaymentMethod.cash
          ? 'cash'
          : 'bankQr',
      orderStatus: 'preparing',
      isCancelled: false,
      pickupEnabled: true,
      items: order.items
          .map(
            (item) => pickup.OrderItemModel(
              name: item.name,
              quantity: item.quantity,
              price: item.total,
              imageAsset: item.imageAsset,
            ),
          )
          .toList(growable: false),
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PreparationFilterSheet(
        selected: _controller.filter,
        countFor: _controller.countFor,
        onSelected: (filter) {
          Navigator.pop(context);
          _controller.setFilter(filter);
        },
      ),
    );
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
              const PreparingStatusBanner(),
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
    if (_controller.loading) return const _PreparingLoading();
    if (_controller.hasError) {
      return _PreparingError(onRetry: _controller.retry);
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
              child: EmptyPreparingState(
                onOrderNowTap: () => _onBottomNavTap(1),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        key: const ValueKey('preparing-orders-list'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return PreparingOrderCard(
            key: ValueKey(order.id),
            order: order,
            onDetailsTap: () => _openDetails(order),
            onTrackTap: () => _track(order),
            onContactTap: () => _contactCounter(order),
            onQrTap: () => _openQr(order),
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
            'Đang chuẩn bị',
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
                  key: const ValueKey('focus-preparing-search'),
                  tooltip: 'Tìm kiếm',
                  onPressed: onSearchTap,
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  key: const ValueKey('open-preparing-filter'),
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
        key: const ValueKey('preparing-search-field'),
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
                  key: const ValueKey('clear-preparing-search'),
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

class _PreparingLoading extends StatelessWidget {
  const _PreparingLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }
}

class _PreparingError extends StatelessWidget {
  const _PreparingError({required this.onRetry});

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

class _PreparationFilterSheet extends StatelessWidget {
  const _PreparationFilterSheet({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final PreparingFilter selected;
  final int Function(PreparingFilter) countFor;
  final ValueChanged<PreparingFilter> onSelected;

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
                'Tiến độ chuẩn bị',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            for (final filter in PreparingFilter.values)
              ListTile(
                key: ValueKey('preparing-filter-${filter.name}'),
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
                          ? preparingBlue
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

  String _label(PreparingFilter filter) {
    return switch (filter) {
      PreparingFilter.all => 'Tất cả',
      PreparingFilter.cooking => 'Đang nấu',
      PreparingFilter.packing => 'Đang đóng gói',
      PreparingFilter.almostReady => 'Sắp sẵn sàng',
      PreparingFilter.ready => 'Sẵn sàng nhận',
    };
  }
}

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Theo dõi đơn hàng',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              order.id,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            PreparationTimeline(order: order),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
