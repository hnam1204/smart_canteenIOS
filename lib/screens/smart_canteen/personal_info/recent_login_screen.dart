import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/colors.dart';

class RecentLoginScreen extends StatefulWidget {
  const RecentLoginScreen({super.key});

  @override
  State<RecentLoginScreen> createState() => _RecentLoginScreenState();
}

class _RecentLoginScreenState extends State<RecentLoginScreen> {
  String? _currentDeviceId;
  bool _loadingDeviceId = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentDeviceId();
  }

  Future<void> _loadCurrentDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentDeviceId = prefs.getString('device_id');
        _loadingDeviceId = false;
      });
    } catch (_) {
      setState(() {
        _loadingDeviceId = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$hour:$minute • $day/$month/$year';
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'android':
        return Icons.phone_android_rounded;
      case 'web':
        return Icons.computer_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _loadingDeviceId) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Đăng nhập gần đây',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Đăng nhập gần đây',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('login_sessions')
            .orderBy('lastActiveAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải lịch sử đăng nhập: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemCount: docs.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final deviceId = doc.id;
              final deviceName = data['deviceName'] as String? ?? 'Thiết bị không rõ';
              final platform = data['platform'] as String? ?? 'Khác';
              final ipAddress = data['ipAddress'] as String? ?? '';
              final location = data['location'] as String? ?? '';

              final loginAtRaw = data['loginAt'];
              final loginAt = loginAtRaw is Timestamp ? loginAtRaw.toDate() : DateTime.now();

              final lastActiveAtRaw = data['lastActiveAt'];
              final lastActiveAt = lastActiveAtRaw is Timestamp ? lastActiveAtRaw.toDate() : DateTime.now();

              // The device is current if either local device ID matches the document ID
              // OR the database explicit flag matches (if device ID was not local)
              final isCurrent = _currentDeviceId != null
                  ? deviceId == _currentDeviceId
                  : (data['isCurrentDevice'] as bool? ?? false);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: AppColors.surface,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.divider.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getPlatformIcon(platform),
                            color: isCurrent ? AppColors.success : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      deviceName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Thiết bị hiện tại',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nền tảng: $platform',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (ipAddress.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'IP: $ipAddress',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Vị trí: $location',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: AppColors.divider),
                              const SizedBox(height: 8),
                              Text(
                                'Đăng nhập: ${_formatDateTime(loginAt)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Hoạt động: ${_formatDateTime(lastActiveAt)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_other_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có lịch sử đăng nhập',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lịch sử đăng nhập của bạn trên các thiết bị sẽ được hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
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
