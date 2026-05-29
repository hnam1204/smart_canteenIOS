import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/utils/app_feedback.dart';
import '../../services/otp_service.dart';
import 'password_reset_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.verificationCode,
    required this.otpService,
  });

  final String email;
  final String verificationCode;
  final OtpService otpService;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await widget.otpService.resetPassword(
        email: widget.email,
        verificationCode: widget.verificationCode,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Đổi mật khẩu thành công.');
      AppNavigator.pushNamedAndRemoveUntil<void>(
        context,
        '/login',
        (_) => false,
      );
    } on OtpApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Không thể đổi mật khẩu. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    showAppSnackBar(
      context,
      message,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResetFlowScaffold(
      title: 'Đặt lại mật khẩu',
      subtitle: 'Nhập mật khẩu mới cho tài khoản',
      onBack: () => Navigator.of(context).pop(),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 52),
            ResetTextField(
              controller: _passwordController,
              hintText: 'Mật khẩu mới',
              prefixIcon: Icons.lock_outline_rounded,
              enabled: !_loading,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới.';
                }
                if (value.length < 8) {
                  return 'Mật khẩu tối thiểu 8 ký tự.';
                }
                return null;
              },
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 17),
            ResetTextField(
              controller: _confirmController,
              hintText: 'Nhập lại mật khẩu',
              prefixIcon: Icons.lock_outline_rounded,
              enabled: !_loading,
              obscureText: _hideConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _resetPassword(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập lại mật khẩu.';
                }
                if (value != _passwordController.text) {
                  return 'Mật khẩu nhập lại không trùng khớp.';
                }
                return null;
              },
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _hideConfirm = !_hideConfirm),
                icon: Icon(
                  _hideConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ResetActionButton(
              label: 'Đổi mật khẩu',
              loading: _loading,
              onPressed: _resetPassword,
            ),
            const SizedBox(height: 25),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => AppNavigator.pushNamedAndRemoveUntil<void>(
                      context,
                      '/login',
                      (_) => false,
                    ),
              child: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
