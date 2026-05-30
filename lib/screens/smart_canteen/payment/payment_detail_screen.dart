import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chi tiết thanh toán'),
      ),
      body: paymentId.isEmpty
          ? const Center(
              child: Text('Không tìm thấy giao dịch.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('payments').doc(paymentId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payment_outlined, size: 56, color: AppColors.textTertiary),
                        SizedBox(height: 14),
                        Text('Giao dịch không tồn tại.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!.data()!;
                final amount = (data['amount'] as num?)?.toInt() ?? 0;
                final method = (data['method'] ?? '') as String;
                final status = (data['status'] ?? '') as String;
                final orderId = (data['orderId'] ?? '') as String;
                final description = (data['description'] ?? '') as String;
                final createdAt = data['createdAt'];
                String dateStr = '';
                if (createdAt is Timestamp) {
                  final d = createdAt.toDate();
                  dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                }

                return SafeArea(
                  child: SingleChildScrollView(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: _paymentStatusColor(status).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _paymentStatusIcon(status),
                                color: _paymentStatusColor(status),
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              _paymentStatusLabel(status),
                              style: TextStyle(
                                color: _paymentStatusColor(status),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              _formatCurrency(amount),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Divider(height: 32),
                          _DetailRow(label: 'Mã giao dịch', value: paymentId),
                          if (orderId.isNotEmpty) _DetailRow(label: 'Đơn hàng', value: orderId),
                          _DetailRow(label: 'Phương thức', value: _methodLabel(method)),
                          if (description.isNotEmpty) _DetailRow(label: 'Nội dung', value: description),
                          if (dateStr.isNotEmpty) _DetailRow(label: 'Thời gian', value: dateStr),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF13A457);
      case 'pending':
        return const Color(0xFFE8A317);
      case 'expired':
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _paymentStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'expired':
      case 'failed':
        return Icons.cancel_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Thanh toán thành công';
      case 'pending':
        return 'Đang chờ thanh toán';
      case 'expired':
        return 'Đã hết hạn';
      case 'failed':
        return 'Thanh toán thất bại';
      default:
        return 'Không xác định';
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'bankQr':
        return 'Chuyển khoản QR';
      case 'cash':
        return 'Tiền mặt';
      default:
        return method.isNotEmpty ? method : 'Khác';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
