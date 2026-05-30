import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../services/notification_service.dart' as push;
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      try {
        await push.NotificationService.instance.getFCMToken();
      } on Object {
        // Token registration must never block a successful authentication.
      }

      if (!mounted) return;
      AppNavigator.pushNamed<void>(context, '/home', replace: true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _authErrorMessage(error.code));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Không thể đăng nhập. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.';
      default:
        return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final compact = screenHeight < 700;
    final headerHeight = (screenHeight * 0.47).clamp(330.0, 360.0);
    final cardTop = headerHeight - (compact ? 55 : 64);
    final horizontalMargin = screenWidth < 360 ? 18.0 : 22.0;
    final bottomSafeSpacing = math.max(media.padding.bottom, 18.0) + 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: bottomSafeSpacing),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - bottomSafeSpacing,
            minWidth: screenWidth,
          ),
          child: SizedBox(
            width: screenWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(
                    height: headerHeight,
                    topPadding: media.padding.top,
                    compact: compact,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalMargin,
                    cardTop,
                    horizontalMargin,
                    10,
                  ),
                  child: _buildLoginCard(compact: compact),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required double height,
    required double topPadding,
    required bool compact,
  }) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          ),
          Positioned(
            right: -34,
            bottom: 33,
            child: Opacity(
              opacity: 0.075,
              child: Image.asset(
                'assets/logos/huflit_logo.png',
                width: 183,
                height: 183,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: compact ? 55 : 62,
                color: const Color(0xFFF6F8FC),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: topPadding + (compact ? 18 : 24)),
            child: Column(
              children: [
                Container(
                  height: compact ? 76 : 82,
                  width: compact ? 76 : 82,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logos/huflit_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: compact ? 15 : 17),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Trường Đại học Ngoại ngữ - Tin học TPHCM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'MY HUFLIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard({required bool compact}) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 390),
        padding: EdgeInsets.fromLTRB(20, compact ? 22 : 26, 20, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF102A43).withValues(alpha: 0.065),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ĐĂNG NHẬP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
              SizedBox(height: compact ? 22 : 27),
              _buildEmailField(),
              const SizedBox(height: 13),
              _buildPasswordField(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => AppNavigator.pushNamed<void>(
                          context,
                          '/forgot-password',
                        ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(top: 15, bottom: 3),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _errorMessage == null
                    ? const SizedBox.shrink()
                    : Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 3),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 53,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.48,
                    ),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 21,
                            width: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.3,
                            ),
                          )
                        : const Text(
                            'ĐĂNG NHẬP',
                            key: ValueKey('text'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => AppNavigator.pushNamed<void>(
                            context,
                            '/register',
                          ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: !_isLoading,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(
        hint: 'Email',
        icon: Icons.mail_outline_rounded,
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return 'Vui lòng nhập email.';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
          return 'Email không hợp lệ.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isLoading,
      obscureText: _hidePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(
        hint: 'Mật khẩu',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          onPressed: _isLoading
              ? null
              : () => setState(() => _hidePassword = !_hidePassword),
          splashRadius: 18,
          icon: Icon(
            _hidePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
        if (value.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự.';
        return null;
      },
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

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.68,
        size.width * 0.63,
        size.height * 0.66,
        size.width,
        size.height * 0.26,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) => false;
}
