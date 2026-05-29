import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../main_shell_screen.dart' show MainShellScreen;
import '../qr_pickup/order_model.dart' as pickup;
import '../qr_pickup/qr_pickup_screen.dart' show QRPickupScreen;
import '../review/review_model.dart' as review;
import '../review/review_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'order_history_controller.dart';
import 'order_model.dart';
import 'widgets/order_filter_tab.dart';
import 'widgets/order_history_card.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrderHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OrderHistoryController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    AppNavigator.replace<void>(
      context,
      builder: (_) => MainShellScreen(initialIndex: index),
    );
  }

  void _viewQr(OrderModel order) {
    AppNavigator.push<void>(
      context,
      builder: (_) => QRPickupScreen(
        orderId: order.id,
        previewOrder: pickup.OrderModel(
          id: order.id,
          placedAt: '${order.date} - ${order.time}',
          readyAt: order.readyAt ?? order.time,
          pickupCounter: order.pickupCounter,
          pickupDescription: order.items.first.name,
          paymentStatus: (order.status == OrderHistoryStatus.completed || order.status == OrderHistoryStatus.delivered)
              ? 'paid'
              : 'pending',
          paymentMethod: 'bankQr',
          orderStatus: switch (order.status) {
            OrderHistoryStatus.pending => 'pending',
            OrderHistoryStatus.preparing => 'preparing',
            OrderHistoryStatus.delivering => 'ready',
            OrderHistoryStatus.delivered => 'delivered',
            OrderHistoryStatus.completed => 'completed',
            OrderHistoryStatus.cancelled => 'cancelled',
          },
          isCancelled: order.status == OrderHistoryStatus.cancelled,
          pickupEnabled: order.status != OrderHistoryStatus.cancelled,
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
        ),
      ),
    );
  }

  void _viewDetails(OrderModel order) {
    AppNavigator.push<void>(
      context,
      builder: (_) => _OrderDetailScreen(order: order),
    );
  }

  void _review(OrderModel order) {
    if (order.hasReview) return;
    AppNavigator.push<void>(
      context,
      builder: (_) => ReviewScreen(
        order: review.ReviewOrderModel(
          id: order.firestoreId.isNotEmpty ? order.firestoreId : order.id,
          orderedAt: '${order.date} - ${order.time}',
          items: order.items
              .map(
                (item) => review.ReviewOrderItemModel(
                  name: item.name,
                  quantity: item.quantity,
                  price: item.price,
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

  void _showFilterOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selected: _controller.filter,
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
      builder: (context, _) {
        final orders = _controller.visibleOrders;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  onBackTap: () => Navigator.maybePop(context),
                  onFilterTap: _showFilterOptions,
                ),
                OrderFilterTab(
                  selectedFilter: _controller.filter,
                  onSelected: _controller.setFilter,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _controller.loading
                        ? const _OrderLoading(key: ValueKey('orders-loading'))
                        : orders.isEmpty
                        ? _EmptyOrders(
                            key: const ValueKey('orders-empty'),
                            onRefresh: _controller.refresh,
                          )
                        : RefreshIndicator(
                            key: const ValueKey('orders-content'),
                            color: AppColors.primary,
                            onRefresh: _controller.refresh,
                            child: ListView.builder(
                              key: const ValueKey('order-history-list'),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return OrderHistoryCard(
                                  key: ValueKey(order.id),
                                  order: order,
                                  onDetailsTap: () => _viewDetails(order),
                                  onQrTap: () => _viewQr(order),
                                  onReviewTap: () => _review(order),
                                );
                              },
                            ),
                          ),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.onBackTap, required this.onFilterTap});

  final VoidCallback onBackTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      child: SizedBox(
        height: 55,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Quay lại',
                onPressed: onBackTap,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.textPrimary,
                iconSize: 21,
              ),
            ),
            const Text(
              'Lịch sử đơn hàng',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const ValueKey('history-filter-button'),
                tooltip: 'Lọc đơn hàng',
                onPressed: onFilterTap,
                icon: const Icon(Icons.filter_alt_outlined),
                color: AppColors.textPrimary,
                iconSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderLoading extends StatelessWidget {
  const _OrderLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 185,
            height: 15,
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

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: const [
          SizedBox(height: 86),
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primaryLight,
            size: 76,
          ),
          SizedBox(height: 20),
          Text(
            'Chưa có đơn hàng',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Đơn hàng phù hợp với bộ lọc sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.selected, required this.onSelected});

  final OrderHistoryFilter selected;
  final ValueChanged<OrderHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Lọc trạng thái đơn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final filter in OrderHistoryFilter.values)
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('sheet-filter-${filter.name}'),
                onTap: () => onSelected(filter),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 21,
                        height: 21,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected == filter
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            width: 1.7,
                          ),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected == filter
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Text(
                        _filterLabel(filter),
                        style: TextStyle(
                          color: selected == filter
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: selected == filter
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(OrderHistoryFilter filter) {
    switch (filter) {
      case OrderHistoryFilter.all:
        return 'Tất cả';
      case OrderHistoryFilter.pending:
        return 'Chờ xác nhận';
      case OrderHistoryFilter.preparing:
        return 'Đang chuẩn bị';
      case OrderHistoryFilter.delivering:
        return 'Đang giao';
      case OrderHistoryFilter.completed:
        return 'Đã hoàn thành';
      case OrderHistoryFilter.cancelled:
        return 'Đã hủy';
    }
  }
}

class _OrderDetailScreen extends StatelessWidget {
  const _OrderDetailScreen({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.date} • ${order.time}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Divider(height: 28),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.quantity}x  ${item.name}'),
                        ),
                        Text(_formatCurrency(item.total)),
                      ],
                    ),
                  ),
                const Divider(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tổng cộng',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _formatCurrency(order.total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(int value) {
  final digits = value.toString();
  final result = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return '$resultđ';
}
