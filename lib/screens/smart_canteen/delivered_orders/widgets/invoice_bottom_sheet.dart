import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivered_status_banner.dart';

class InvoiceBottomSheet extends StatelessWidget {
  const InvoiceBottomSheet({
    super.key,
    required this.order,
    required this.onDownloadTap,
    required this.onShareTap,
  });

  final OrderModel order;
  final VoidCallback onDownloadTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.paddingOf(context).bottom + 18,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
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
                'Hóa đơn thanh toán',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 17),
              _InfoRow(title: 'Mã hóa đơn', value: order.invoice.id),
              _InfoRow(title: 'Mã đơn hàng', value: order.id),
              _InfoRow(title: 'Ngày thanh toán', value: order.invoice.paidAt),
              _InfoRow(
                title: 'Phương thức',
                value: paymentMethodLabel(order.paymentMethod),
              ),
              const Divider(height: 29, color: AppColors.divider),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item.quantity}x  ${item.name}')),
                      Text(formatCurrency(item.total)),
                    ],
                  ),
                ),
              const Divider(height: 19, color: AppColors.divider),
              _InfoRow(
                title: 'Tạm tính',
                value: formatCurrency(order.subtotal),
              ),
              _InfoRow(
                title: 'Giảm giá',
                value: '-${formatCurrency(order.invoice.discount)}',
                valueColor: deliveredGreen,
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Text(
                    'Tổng tiền',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency(order.total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: deliveredGreenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: deliveredGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đã thanh toán',
                      style: TextStyle(
                        color: deliveredGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('share-invoice'),
                      onPressed: onShareTap,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Chia sẻ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('download-invoice'),
                      onPressed: onDownloadTap,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Tải hóa đơn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value, this.valueColor});

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
