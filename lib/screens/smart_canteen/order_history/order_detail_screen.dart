import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, this.orderId = ''});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    if (orderId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: const Text('Chi tiết đơn hàng'),
        ),
        body: const Center(
          child: Text('Không tìm thấy đơn hàng.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 14),
                  Text('Đơn hàng không tồn tại.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final orderCode = (data['orderCode'] ?? '') as String;
          final status = (data['orderStatus'] ?? '') as String;
          final totalAmount = (data['totalAmount'] as num?)?.toInt() ?? 0;
          final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final createdAt = data['createdAt'];
          String dateStr = '';
          if (createdAt is Timestamp) {
            final d = createdAt.toDate();
            dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                orderCode.isEmpty ? orderId : orderCode,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                        const Divider(height: 28),
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${(item['quantity'] as num?)?.toInt() ?? 1}x  ${item['name'] ?? ''}',
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                ),
                                Text(
                                  _formatCurrency((item['itemTotal'] as num?)?.toInt() ?? 0),
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ),
                            Text(
                              _formatCurrency(totalAmount),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE8A317);
      case 'confirmed':
      case 'preparing':
        return const Color(0xFF2176E8);
      case 'ready':
      case 'delivering':
        return AppColors.primary;
      case 'completed':
      case 'delivered':
        return const Color(0xFF13A457);
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'ready':
        return 'Sẵn sàng nhận';
      case 'delivering':
        return 'Đang giao';
      case 'completed':
      case 'delivered':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
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
