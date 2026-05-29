import 'package:flutter/material.dart';

enum Gender { male, female, other }

enum SecurityAction {
  changePassword,
  emailVerification,
  phoneVerification,
  loginActivity,
}

class AccountSecurityModel {
  const AccountSecurityModel({
    required this.action,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.verified,
  });

  final SecurityAction action;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool? verified;
}

class ProfileStatsModel {
  const ProfileStatsModel({
    required this.points,
    required this.memberTier,
    required this.orderCount,
    required this.totalSpent,
  });

  final int points;
  final String memberTier;
  final int orderCount;
  final int totalSpent;
}

class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.studentId,
    required this.department,
    required this.address,
    required this.note,
    required this.avatarVariant,
    required this.avatarUrl,
    required this.stats,
    required this.securityItems,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final Gender gender;
  final String studentId;
  final String department;
  final String address;
  final String note;
  final int avatarVariant;
  final String avatarUrl;
  final ProfileStatsModel stats;
  final List<AccountSecurityModel> securityItems;

  UserProfileModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    Gender? gender,
    String? studentId,
    String? department,
    String? address,
    String? note,
    int? avatarVariant,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      address: address ?? this.address,
      note: note ?? this.note,
      avatarVariant: avatarVariant ?? this.avatarVariant,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stats: stats,
      securityItems: securityItems,
    );
  }
}

String genderLabel(Gender gender) {
  return switch (gender) {
    Gender.male => 'Nam',
    Gender.female => 'Nữ',
    Gender.other => 'Khác',
  };
}

String formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String formatProfileCurrency(int value) {
  final valueString = value.toString();
  final formatted = StringBuffer();
  for (var index = 0; index < valueString.length; index++) {
    if (index > 0 && (valueString.length - index) % 3 == 0) {
      formatted.write('.');
    }
    formatted.write(valueString[index]);
  }
  formatted.write('đ');
  return formatted.toString();
}

final demoPersonalProfile = UserProfileModel(
  uid: 'demo-user',
  fullName: 'Nguyễn Thảo Vy',
  email: 'thaovy.nguyen@gmail.com',
  phone: '0901 234 567',
  dateOfBirth: DateTime(2005, 9, 18),
  gender: Gender.female,
  studentId: 'SV2301542',
  department: 'Công nghệ thông tin - K23',
  address: 'Ký túc xá A, Đại học Smart Canteen',
  note: 'Ưu tiên món ít cay và không hành.',
  avatarVariant: 0,
  avatarUrl: '',
  stats: ProfileStatsModel(
    points: 1250,
    memberTier: 'Gold',
    orderCount: 36,
    totalSpent: 1680000,
  ),
  securityItems: [
    AccountSecurityModel(
      action: SecurityAction.changePassword,
      title: 'Đổi mật khẩu',
      subtitle: 'Cập nhật lần cuối 21/05/2026',
      icon: Icons.lock_outline_rounded,
    ),
    AccountSecurityModel(
      action: SecurityAction.emailVerification,
      title: 'Xác thực email',
      subtitle: 'Email của bạn đã được bảo vệ',
      icon: Icons.mark_email_read_outlined,
      verified: true,
    ),
    AccountSecurityModel(
      action: SecurityAction.phoneVerification,
      title: 'Xác thực số điện thoại',
      subtitle: 'Hoàn tất để bảo mật tài khoản',
      icon: Icons.phone_android_outlined,
      verified: false,
    ),
    AccountSecurityModel(
      action: SecurityAction.loginActivity,
      title: 'Đăng nhập gần đây',
      subtitle: 'iPhone 15 Pro • Thành phố Hồ Chí Minh',
      icon: Icons.devices_outlined,
    ),
  ],
);
