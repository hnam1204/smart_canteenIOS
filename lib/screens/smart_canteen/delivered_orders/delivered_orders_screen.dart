import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../main_shell_screen.dart';
import '../review/review_model.dart' as review;
import '../review/review_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'delivered_orders_controller.dart';
import 'order_model.dart';
import 'widgets/delivered_order_card.dart';
import 'widgets/delivered_order_detail_sheet.dart';
import 'widgets/delivered_status_banner.dart';
import 'widgets/delivered_summary_card.dart';
import 'widgets/empty_delivered_state.dart';
import 'widgets/invoice_bottom_sheet.dart';

class DeliveredOrdersScreen extends StatefulWidget {
  const DeliveredOrdersScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<DeliveredOrdersScreen> createState() => _DeliveredOrdersScreenState();
}

class _DeliveredOrdersScreenState extends State<DeliveredOrdersScreen> {
  late final DeliveredOrdersController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = DeliveredOrdersController()..load();
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
      builder: (_) => DeliveredOrderDetailSheet(order: order),
    );
  }

  void _review(OrderModel order) {
    if (order.reviewed) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReviewDetailSheet(order: order),
      );
      return;
    }
    AppNavigator.push<void>(
      context,
      builder: (_) => ReviewScreen(
        order: review.ReviewOrderModel(
          id: order.id,
          orderedAt: order.orderedAt,
          items: order.items
              .map(
                (item) => review.ReviewOrderItemModel(
                  name: item.name,
                  quantity: item.quantity,
                  price: item.total,
                  imageAsset: item.imageAsset,
                ),
              )
              .toList(growable: false),
        ),
        cartCount: widget.cartCount,
        notificationCount: widget.notificationCount,
      ),
    );
  }

  void _reorder(OrderModel order) {
    showAppSnackBar(
      context,
      'Đã thêm ${order.itemCount} món của ${order.id} vào giỏ hàng.',
      icon: Icons.shopping_cart_checkout_rounded,
      iconColor: AppColors.primary,
    );
  }

  void _openInvoice(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => InvoiceBottomSheet(
        order: order,
        onDownloadTap: () {
          Navigator.pop(sheetContext);
          showAppSnackBar(context, 'Đã tải hóa đơn ${order.invoice.id}.');
        },
        onShareTap: () {
          Navigator.pop(sheetContext);
          showAppSnackBar(
            context,
            'Đã sẵn sàng chia sẻ hóa đơn ${order.invoice.id}.',
            icon: Icons.share_outlined,
            iconColor: AppColors.primary,
          );
        },
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveredFilterSheet(
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
              const DeliveredStatusBanner(),
              _SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _controller.updateSearch,
                onClear: _clearSearch,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DeliveredSummaryCard(
                  totalDelivered: _controller.totalDelivered,
                  totalSpent: _controller.totalSpent,
                  awaitingReview: _controller.awaitingReview,
                  rewardPoints: _controller.rewardPoints,
                ),
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
    if (_controller.loading) return const _DeliveredLoading();
    if (_controller.hasError) {
      return _DeliveredError(onRetry: _controller.retry);
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
              height: 350,
              child: EmptyDeliveredState(
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
        key: const ValueKey('delivered-orders-list'),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return DeliveredOrderCard(
            key: ValueKey(order.id),
            order: order,
            onDetailsTap: () => _openDetails(order),
            onReviewTap: () => _review(order),
            onReorderTap: () => _reorder(order),
            onInvoiceTap: () => _openInvoice(order),
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
            'Đã giao',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const ValueKey('focus-delivered-search'),
                  tooltip: 'Tìm kiếm',
                  onPressed: onSearchTap,
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  key: const ValueKey('open-delivered-filter'),
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
        key: const ValueKey('delivered-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Mã đơn, món ăn hoặc tên shipper',
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
                  key: const ValueKey('clear-delivered-search'),
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

class _DeliveredLoading extends StatelessWidget {
  const _DeliveredLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        height: 345,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }
}

class _DeliveredError extends StatelessWidget {
  const _DeliveredError({required this.onRetry});

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

class _DeliveredFilterSheet extends StatelessWidget {
  const _DeliveredFilterSheet({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final DeliveredFilter selected;
  final int Function(DeliveredFilter) countFor;
  final ValueChanged<DeliveredFilter> onSelected;

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
              height: 4,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lọc đơn đã giao',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            for (final filter in DeliveredFilter.values)
              ListTile(
                key: ValueKey('delivered-filter-${filter.name}'),
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
                          ? deliveredGreen
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

  String _label(DeliveredFilter filter) {
    return switch (filter) {
      DeliveredFilter.all => 'Tất cả',
      DeliveredFilter.awaitingReview => 'Chưa đánh giá',
      DeliveredFilter.reviewed => 'Đã đánh giá',
    };
  }
}

class _ReviewDetailSheet extends StatelessWidget {
  const _ReviewDetailSheet({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            const SizedBox(height: 18),
            const Text(
              'Đánh giá của bạn',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              order.id,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: AppColors.primary),
                Icon(Icons.star_rounded, color: AppColors.primary),
                Icon(Icons.star_rounded, color: AppColors.primary),
                Icon(Icons.star_rounded, color: AppColors.primary),
                Icon(Icons.star_rounded, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Món ngon, đóng gói đẹp và giao đúng giờ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
