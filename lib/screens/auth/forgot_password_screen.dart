import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/utils/app_feedback.dart';
import '../../services/otp_service.dart';
import 'password_reset_widgets.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.otpService});

  final OtpService? otpService;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final OtpService _otpService = widget.otpService ?? OtpService();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    if (widget.otpService == null) _otpService.close();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    setState(() => _loading = true);
    try {
      if (widget.otpService == null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (!mounted) return;
        showAppSnackBar(
          context,
          'Liên kết đặt lại mật khẩu đã được gửi đến email.',
        );
        AppNavigator.pushNamedAndRemoveUntil<void>(
          context,
          '/login',
          (_) => false,
        );
        return;
      }
      await _otpService.sendOtp(email);
      if (!mounted) return;
      showAppSnackBar(context, 'Mã OTP đã được gửi đến email.');
      AppNavigator.push<void>(
        context,
        builder: (_) => VerifyOtpScreen(email: email, otpService: _otpService),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        error.message ?? 'Không thể gửi email đặt lại mật khẩu.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
    } on OtpApiException catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        error.message,
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Không thể gọi API OTP. Hãy kiểm tra Flask đang chạy.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResetFlowScaffold(
      withLogo: true,
      title: 'Quên mật khẩu',
      subtitle: 'Nhập email để nhận mã OTP',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 68),
            ResetTextField(
              controller: _emailController,
              hintText: 'Nhập email của bạn',
              prefixIcon: Icons.mail_outline_rounded,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Vui lòng nhập email.';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
                  return 'Email không hợp lệ.';
                }
                return null;
              },
              onSubmitted: (_) => _sendOtp(),
            ),
            const SizedBox(height: 25),
            ResetActionButton(
              label: 'Gửi mã OTP',
              loading: _loading,
              onPressed: _sendOtp,
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'hoặc',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
