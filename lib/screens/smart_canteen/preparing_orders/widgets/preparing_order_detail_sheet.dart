import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_food_image.dart';
import '../order_model.dart';
import 'preparation_progress_bar.dart';
import 'preparation_timeline.dart';

class PreparingOrderDetailSheet extends StatelessWidget {
  const PreparingOrderDetailSheet({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chi tiết đơn hàng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _InfoRow(title: 'Mã đơn', value: order.id),
                  const SizedBox(height: 11),
                  _InfoRow(title: 'Thời gian đặt', value: order.orderedAt),
                  const SizedBox(height: 11),
                  _InfoRow(title: 'Nhận món', value: order.pickupCounter),
                  const SizedBox(height: 14),
                  PreparationProgressBar(order: order),
                ],
              ),
            ),
            const SizedBox(height: 13),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiến trình trạng thái',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 17),
                  PreparationTimeline(order: order),
                ],
              ),
            ),
            const SizedBox(height: 13),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Món đã đặt',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 13),
                  for (final item in order.items) _ItemTile(item: item),
                  const Divider(height: 27, color: AppColors.divider),
                  _InfoRow(
                    title: 'Thanh toán',
                    value: paymentMethodLabel(order.paymentMethod),
                  ),
                  if (order.note != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(title: 'Ghi chú', value: order.note!),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        formatCurrency(order.total),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đơn đang được chế biến nên không thể hủy lúc này.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Không thể hủy khi đang chuẩn bị'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppFoodImage(
              source: item.imageAsset,
              height: 48,
              width: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${item.quantity}x',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(item.total),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
