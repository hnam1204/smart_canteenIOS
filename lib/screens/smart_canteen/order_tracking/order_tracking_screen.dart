import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/firestore_models.dart';
import '../main_shell_screen.dart';
import '../payment/payment_model.dart' show formatPaymentMoney;

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TrackingHeader(onHome: () => _goHome(context)),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _TrackingSkeleton();
                  }
                  if (snapshot.hasError) {
                    return const _TrackingMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Không thể theo dõi đơn hàng',
                      message: 'Kết nối realtime đang gặp sự cố.',
                    );
                  }
                  final document = snapshot.data;
                  if (document == null || !document.exists) {
                    return const _TrackingMessage(
                      icon: Icons.receipt_long_outlined,
                      title: 'Không tìm thấy đơn hàng',
                      message: 'Đơn hàng chưa sẵn sàng để theo dõi.',
                    );
                  }

                  final order = OrderModel.fromFirestore(document);
                  return _TrackingContent(order: order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MainShellScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
              color: AppColors.textPrimary,
            ),
          ),
          const Expanded(
            child: Text(
              'Theo dõi đơn hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: IconButton(
              tooltip: 'Trang chủ',
              onPressed: onHome,
              icon: const Icon(Icons.home_outlined),
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  const _TrackingContent({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 370
        ? 14.0
        : 18.0;
    final activeIndex = _activeIndex(order.orderStatus);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            5,
            horizontalPadding,
            24,
          ),
          children: [
            _TrackingSummary(order: order),
            const SizedBox(height: 14),
            _TimelineCard(activeIndex: activeIndex),
            const SizedBox(height: 14),
            _OrderItemsCard(order: order),
          ],
        ),
      ),
    );
  }

  int _activeIndex(String status) {
    return switch (status.trim().toLowerCase()) {
      'pending' => 0,
      'preparing' => 1,
      'ready' || 'ready_to_pickup' => 2,
      'completed' || 'delivered' || 'received' => 3,
      _ => 0,
    };
  }
}

class _TrackingSummary extends StatelessWidget {
  const _TrackingSummary({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderCode.isEmpty ? order.id : order.orderCode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _PaymentChip(status: order.paymentStatus),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Tổng tiền',
            value: formatPaymentMoney(order.totalAmount),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Quầy nhận', value: order.pickupCounter),
          const SizedBox(height: 10),
          _InfoRow(label: 'Trạng thái', value: _statusLabel(order.orderStatus)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} - ${two(date.hour)}:${two(date.minute)}';
  }

  String _statusLabel(String status) {
    return switch (status.trim().toLowerCase()) {
      'pending' => 'Chờ xác nhận',
      'preparing' => 'Đang chuẩn bị',
      'ready' || 'ready_to_pickup' => 'Sẵn sàng nhận món',
      'completed' || 'delivered' || 'received' => 'Đã nhận món',
      'cancelled' => 'Đã hủy',
      _ => 'Đang xử lý',
    };
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.activeIndex});

  final int activeIndex;

  static const _steps = [
    (label: 'Chờ xác nhận', icon: Icons.hourglass_top_rounded),
    (label: 'Đang chuẩn bị', icon: Icons.restaurant_rounded),
    (label: 'Sẵn sàng nhận món', icon: Icons.shopping_bag_rounded),
    (label: 'Đã nhận món', icon: Icons.check_circle_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          for (var index = 0; index < _steps.length; index++)
            _TimelineStep(
              label: _steps[index].label,
              icon: _steps[index].icon,
              active: index <= activeIndex,
              current: index == activeIndex,
              showLine: index != _steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.active,
    required this.current,
    required this.showLine,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool current;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.field,
                shape: BoxShape.circle,
                boxShadow: current
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: active ? Colors.white : color, size: 20),
            ),
            if (showLine)
              Container(
                width: 3,
                height: 38,
                color: active ? AppColors.primary : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Món đã đặt',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'x${item.quantity}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatPaymentMoney(item.total),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status.trim().toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFFECFDF5) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        paid ? 'Đã thanh toán' : 'Chờ thanh toán',
        style: TextStyle(
          color: paid ? AppColors.success : AppColors.primary,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingSkeleton extends StatelessWidget {
  const _TrackingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, index) => Container(
        height: index == 1 ? 260 : 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            height: 16,
            width: 160,
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

class _TrackingMessage extends StatelessWidget {
  const _TrackingMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 54),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
