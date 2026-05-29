import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import 'profile_text_field.dart';

class PersonalInfoForm extends StatelessWidget {
  const PersonalInfoForm({
    super.key,
    required this.formKey,
    required this.editing,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.birthDateController,
    required this.genderController,
    required this.studentIdController,
    required this.departmentController,
    required this.addressController,
    required this.noteController,
    required this.onBirthDateTap,
    required this.onGenderTap,
  });

  final GlobalKey<FormState> formKey;
  final bool editing;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController birthDateController;
  final TextEditingController genderController;
  final TextEditingController studentIdController;
  final TextEditingController departmentController;
  final TextEditingController addressController;
  final TextEditingController noteController;
  final VoidCallback onBirthDateTap;
  final VoidCallback onGenderTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 15),
            ProfileTextField(
              key: const ValueKey('personal-name'),
              label: 'Họ và tên',
              icon: Icons.person_outline_rounded,
              controller: fullNameController,
              enabled: editing,
              validator: _required,
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              key: const ValueKey('personal-email'),
              label: 'Email',
              icon: Icons.email_outlined,
              controller: emailController,
              enabled: editing,
              keyboardType: TextInputType.emailAddress,
              validator: _email,
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              key: const ValueKey('personal-phone'),
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
              controller: phoneController,
              enabled: editing,
              keyboardType: TextInputType.phone,
              validator: _phone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ProfileTextField(
                    key: const ValueKey('personal-birth-date'),
                    label: 'Ngày sinh',
                    icon: Icons.cake_outlined,
                    controller: birthDateController,
                    enabled: editing,
                    readOnly: true,
                    onTap: onBirthDateTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ProfileTextField(
                    key: const ValueKey('personal-gender'),
                    label: 'Giới tính',
                    icon: Icons.wc_outlined,
                    controller: genderController,
                    enabled: editing,
                    readOnly: true,
                    onTap: onGenderTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              key: const ValueKey('personal-student-id'),
              label: 'Mã sinh viên / nhân viên',
              icon: Icons.badge_outlined,
              controller: studentIdController,
              enabled: editing,
              validator: _required,
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              key: const ValueKey('personal-department'),
              label: 'Lớp / Khoa / Phòng ban',
              icon: Icons.school_outlined,
              controller: departmentController,
              enabled: editing,
              validator: _required,
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              key: const ValueKey('personal-address'),
              label: 'Địa chỉ',
              icon: Icons.location_on_outlined,
              controller: addressController,
              enabled: editing,
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              key: const ValueKey('personal-note'),
              label: 'Ghi chú cá nhân',
              icon: Icons.notes_rounded,
              controller: noteController,
              enabled: editing,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập thông tin';
    return null;
  }

  static String? _email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? _phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 11) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
}
