import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/app_feedback.dart';

class ChangePasswordBottomSheet extends StatefulWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  State<ChangePasswordBottomSheet> createState() => _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Không tìm thấy người dùng hiện tại.',
        );
      }

      final email = user.email;
      if (email == null) {
        throw FirebaseAuthException(
          code: 'no-email',
          message: 'Không tìm thấy email người dùng.',
        );
      }

      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      try {
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Reauthenticate
          final credential = EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);
          // Retry update
          await user.updatePassword(newPassword);
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(
        context,
        'Đổi mật khẩu thành công',
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Thay đổi mật khẩu thất bại.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Mật khẩu hiện tại không chính xác.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu mới quá yếu. Yêu cầu ít nhất 6 ký tự.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Tài khoản của bạn đã bị vô hiệu hóa.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        errorMessage,
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Đã xảy ra lỗi: $e',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 18 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Đổi mật khẩu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              // Current Password Field
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Mật khẩu hiện tại',
                  icon: Icons.lock_open_rounded,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // New Password Field
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Mật khẩu mới',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới.';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu mới cần tối thiểu 6 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Confirm New Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Nhập lại mật khẩu mới',
                  icon: Icons.lock_reset_rounded,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập lại mật khẩu mới.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không trùng khớp.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Action Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.48),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.3,
                          ),
                        )
                      : const Text(
                          'CẬP NHẬT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13.5),
      prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F6FA),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
    );
  }
}
