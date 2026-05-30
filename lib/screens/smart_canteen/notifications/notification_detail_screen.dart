import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});

  final String notificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chi tiết thông báo'),
      ),
      body: notificationId.isEmpty
          ? const Center(
              child: Text('Không tìm thấy thông báo.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('notifications').doc(notificationId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textTertiary),
                        SizedBox(height: 14),
                        Text('Thông báo không tồn tại.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!.data()!;
                final title = (data['title'] ?? '') as String;
                final message = (data['message'] ?? '') as String;
                final type = (data['type'] ?? '') as String;
                final createdAt = data['createdAt'];
                String dateStr = '';
                if (createdAt is Timestamp) {
                  final d = createdAt.toDate();
                  dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                }

                // Mark as read
                if (data['isRead'] != true) {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notificationId)
                      .update({'isRead': true}).catchError((_) {});
                }

                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
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
                                color: _typeColor(type).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _typeIcon(type),
                                color: _typeColor(type),
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF2176E8);
      case 'payment':
        return const Color(0xFF13A457);
      case 'support':
        return AppColors.primary;
      case 'voucher':
        return const Color(0xFF13A457);
      case 'reward':
        return const Color(0xFF7C4DCC);
      case 'review':
        return const Color(0xFFE28743);
      case 'promotion':
        return AppColors.primary;
      case 'system':
        return const Color(0xFFE74680);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'support':
        return Icons.support_agent_rounded;
      case 'voucher':
        return Icons.card_giftcard_rounded;
      case 'reward':
        return Icons.celebration_rounded;
      case 'review':
        return Icons.rate_review_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'system':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }
}
