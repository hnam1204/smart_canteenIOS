import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../main_shell_screen.dart';
import '../qr_pickup/order_model.dart' as pickup;
import '../qr_pickup/qr_pickup_screen.dart';
import '../review/review_model.dart' as review;
import '../review/review_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'all_orders_controller.dart';
import 'order_model.dart';
import 'widgets/empty_orders_state.dart';
import 'widgets/order_card.dart';
import 'widgets/order_detail_bottom_sheet.dart';
import 'widgets/order_filter_tabs.dart';
import 'widgets/order_summary_card.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({
    super.key,
    this.initialFilter = OrderFilter.all,
    this.cartCount = 0,
    this.notificationCount = 0,
    this.debugOrders,
  });

  final OrderFilter initialFilter;
  final int cartCount;
  final int notificationCount;
  final List<OrderModel>? debugOrders;

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  late final AllOrdersController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _hideStats = false;

  @override
  void initState() {
    super.initState();
    _controller = AllOrdersController(
      initialFilter: widget.initialFilter,
      offlineOrders: widget.debugOrders,
    )..load();
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
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    _onBottomNavTap(4);
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
  }

  bool _onOrdersScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final offset = notification.metrics.pixels;
    final shouldHide = offset > 60
        ? true
        : offset <= 20
        ? false
        : _hideStats;
    if (shouldHide != _hideStats) {
      setState(() => _hideStats = shouldHide);
    }
    return false;
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selected: _controller.filter,
        countFor: _controller.countFor,
        onSelected: (filter) {
          Navigator.pop(context);
          _controller.setFilter(filter);
        },
      ),
    );
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Hủy đơn hàng?'),
        content: Text('Bạn muốn hủy đơn ${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
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

  void _track(OrderModel order) {
    showAppSnackBar(
      context,
      '${order.id} đang được chuẩn bị tại ${order.pickupCounter}.',
      icon: Icons.location_searching_rounded,
      iconColor: AppColors.primary,
    );
  }

  void _openQr(OrderModel order) {
    if (order.items.isEmpty) {
      showAppSnackBar(
        context,
        'Đơn hàng chưa có món để tạo mã QR.',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primary,
      );
      return;
    }
    AppNavigator.push<void>(
      context,
      builder: (_) => QRPickupScreen(
        orderId: order.id,
        previewOrder: _asPickupOrder(order),
      ),
    );
  }

  void _openReview(OrderModel order) {
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
                  price: item.total ~/ item.quantity,
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
      'Đã thêm ${order.itemCount} món vào giỏ hàng.',
      icon: Icons.shopping_cart_checkout_rounded,
      iconColor: AppColors.primary,
    );
    _onBottomNavTap(2);
  }

  void _openDetails(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => OrderDetailBottomSheet(
        order: order,
        onCancelTap: () {
          Navigator.pop(sheetContext);
          _cancelOrder(order);
        },
        onTrackTap: () => _track(order),
        onQrTap: () {
          Navigator.pop(sheetContext);
          _openQr(order);
        },
        onReviewTap: () {
          Navigator.pop(sheetContext);
          _openReview(order);
        },
        onReorderTap: () {
          Navigator.pop(sheetContext);
          _reorder(order);
        },
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
      paymentStatus: switch (order.paymentStatus) {
        PaymentStatus.pending => 'pending',
        PaymentStatus.unpaid => 'unpaid',
        PaymentStatus.paid => 'paid',
        PaymentStatus.failed => 'failed',
        PaymentStatus.expired => 'expired',
        PaymentStatus.refunded => 'unpaid',
      },
      paymentMethod: order.paymentMethod.toLowerCase().contains('cash')
          ? 'cash'
          : 'bankQr',
      orderStatus: switch (order.status) {
        OrderStatus.pending => 'pending',
        OrderStatus.preparing => 'preparing',
        OrderStatus.delivering => 'delivering',
        OrderStatus.delivered => 'delivered',
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
      },
      isCancelled: order.status == OrderStatus.cancelled,
      pickupEnabled:
          order.pickupEnabled && order.status != OrderStatus.cancelled,
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
                  onFilterTap: _showFilters,
                ),
                _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _controller.updateSearch,
                  onClear: _clearSearch,
                ),
                const SizedBox(height: 12),
                OrderFilterTabs(
                  selected: _controller.filter,
                  countFor: _controller.countFor,
                  onSelected: _controller.setFilter,
                ),
                if (!_controller.loading && !_controller.hasError)
                  _AnimatedOrderSummary(
                    hidden: _hideStats,
                    child: OrderSummaryCard(
                      totalOrders: _controller.totalOrders,
                      totalSpent: _controller.totalSpent,
                      processingOrders: _controller.processingOrders,
                    ),
                  ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onOrdersScroll,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CanteenBottomNavBar(
            selectedIndex: -1,
            cartCount: widget.cartCount,
            notificationCount: widget.notificationCount,
            onTap: _onBottomNavTap,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_controller.loading) return const _OrdersLoading();
    if (_controller.hasError) {
      return _OrdersError(
        message: _controller.errorMessage,
        onRetry: _controller.retry,
      );
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
              height: 430,
              child: EmptyOrdersState(onOrderNowTap: () => _onBottomNavTap(1)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        key: const ValueKey('all-orders-list'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            key: ValueKey(order.id),
            order: order,
            onDetailsTap: () => _openDetails(order),
            onCancelTap: () => _cancelOrder(order),
            onTrackTap: () => _track(order),
            onQrTap: () => _openQr(order),
            onReviewTap: () => _openReview(order),
            onReorderTap: () => _reorder(order),
          );
        },
      ),
    );
  }
}

class _AnimatedOrderSummary extends StatelessWidget {
  const _AnimatedOrderSummary({required this.hidden, required this.child});

  final bool hidden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Animate only when the scroll passes a threshold, not on every pixel.
    // Align heightFactor lets the responsive summary collapse to a true height of 0.
    return TweenAnimationBuilder<double>(
      key: const ValueKey('all-orders-summary-panel'),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: hidden ? 0 : 1),
      builder: (context, factor, child) => ClipRect(
        child: Align(
          heightFactor: factor,
          alignment: Alignment.topCenter,
          child: Opacity(opacity: factor, child: child),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: child,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
      child: SizedBox(
        height: 54,
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
              'Tất cả đơn hàng',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('focus-order-search'),
                    tooltip: 'Tìm kiếm đơn hàng',
                    onPressed: onSearchTap,
                    icon: const Icon(Icons.search_rounded, size: 23),
                  ),
                  IconButton(
                    key: const ValueKey('open-order-filter'),
                    tooltip: 'Bộ lọc đơn hàng',
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
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
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
        key: const ValueKey('order-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Mã đơn hàng, tên món, trạng thái',
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
                  key: const ValueKey('clear-order-search'),
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

class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 13),
      itemBuilder: (_, _) => Container(
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String? message;
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
          const SizedBox(height: 14),
          const Text(
            'Không thể tải đơn hàng',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          if (message != null && message!.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 13),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final OrderFilter selected;
  final int Function(OrderFilter filter) countFor;
  final ValueChanged<OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 17),
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
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lọc trạng thái',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            for (final filter in OrderFilter.values)
              ListTile(
                key: ValueKey('sheet-order-filter-${filter.name}'),
                onTap: () => onSelected(filter),
                title: Text(_filterTitle(filter)),
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

  String _filterTitle(OrderFilter filter) {
    return switch (filter) {
      OrderFilter.all => 'Tất cả',
      OrderFilter.pending => 'Chờ xác nhận',
      OrderFilter.preparing => 'Đang chuẩn bị',
      OrderFilter.delivering => 'Đang giao',
      OrderFilter.completed => 'Đã hoàn thành',
      OrderFilter.cancelled => 'Đã hủy',
    };
  }
}
