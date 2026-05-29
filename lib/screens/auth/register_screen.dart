import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/app_feedback.dart';
import 'register_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterController(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = context.read<RegisterController>();
    final successful = await controller.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      studentId: _studentIdController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
    );

    if (!mounted || !successful) return;
    showAppSnackBar(context, 'Đăng ký thành công');
    AppNavigator.pushNamed<void>(context, '/login', replace: true);
  }

  void _openLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      AppNavigator.pushNamed<void>(context, '/login', replace: true);
    }
  }

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email sinh viên.';
    if (!RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(email)) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim().replaceAll(' ', '') ?? '';
    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại.';
    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (password.length < 8) return 'Mật khẩu cần tối thiểu 8 ký tự.';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu.';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu nhập lại không trùng khớp.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.height < 760;
    final headerHeight = (media.size.height * 0.38).clamp(292.0, 344.0);
    final horizontalMargin = media.size.width < 360 ? 16.0 : 22.0;
    final cardTop = headerHeight - (compact ? 38 : 46);
    final bottomPadding = math.max(media.padding.bottom, 16.0) + 18;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: media.size.width,
              minHeight: media.size.height - bottomPadding,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _RegisterHeader(
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
                    0,
                  ),
                  child: _RegisterCard(
                    compact: compact,
                    formKey: _formKey,
                    fullNameController: _fullNameController,
                    emailController: _emailController,
                    studentIdController: _studentIdController,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    hidePassword: _hidePassword,
                    hideConfirmPassword: _hideConfirmPassword,
                    onTogglePassword: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    onToggleConfirmPassword: () => setState(
                      () => _hideConfirmPassword = !_hideConfirmPassword,
                    ),
                    onSubmit: _submit,
                    onOpenLogin: _openLogin,
                    onPasswordChanged: (_) => _formKey.currentState?.validate(),
                    fullNameValidator: (value) =>
                        _requiredValidator(value, 'Vui lòng nhập họ và tên.'),
                    emailValidator: _emailValidator,
                    studentIdValidator: (value) => _requiredValidator(
                      value,
                      'Vui lòng nhập mã số sinh viên.',
                    ),
                    phoneValidator: _phoneValidator,
                    passwordValidator: _passwordValidator,
                    confirmPasswordValidator: _confirmPasswordValidator,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({
    required this.height,
    required this.topPadding,
    required this.compact,
  });

  final double height;
  final double topPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.brandGradient),
          ),
          Positioned(
            right: -38,
            bottom: 34,
            child: Opacity(
              opacity: 0.075,
              child: Image.asset(
                'assets/logos/huflit_logo.png',
                width: 180,
                height: 180,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: ClipPath(
              clipper: _RegisterWaveClipper(),
              child: Container(height: compact ? 47 : 56, color: background),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding + (compact ? 11 : 18)),
              child: Column(
                children: [
                  Container(
                    height: compact ? 68 : 78,
                    width: compact ? 68 : 78,
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
                    child: Image.asset('assets/logos/huflit_logo.png'),
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  const Text(
                    'Trường Đại học Ngoại ngữ - Tin học TPHCM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.compact,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.studentIdController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.hidePassword,
    required this.hideConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
    required this.onOpenLogin,
    required this.onPasswordChanged,
    required this.fullNameValidator,
    required this.emailValidator,
    required this.studentIdValidator,
    required this.phoneValidator,
    required this.passwordValidator,
    required this.confirmPasswordValidator,
  });

  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController studentIdController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool hidePassword;
  final bool hideConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;
  final VoidCallback onOpenLogin;
  final ValueChanged<String> onPasswordChanged;
  final FormFieldValidator<String> fullNameValidator;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> studentIdValidator;
  final FormFieldValidator<String> phoneValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> confirmPasswordValidator;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<RegisterController>();
    final gap = compact ? 10.0 : 12.0;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 410),
        padding: EdgeInsets.fromLTRB(20, compact ? 22 : 27, 20, 21),
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.cardShadow,
        ),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ĐĂNG KÝ TÀI KHOẢN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark ? AppColors.primaryLight : AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
              SizedBox(height: compact ? 19 : 24),
              _AnimatedAuthField(
                controller: fullNameController,
                hintText: 'Họ và tên',
                icon: Icons.person_outline_rounded,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.next,
                validator: fullNameValidator,
              ),
              SizedBox(height: gap),
              _AnimatedAuthField(
                controller: emailController,
                hintText: 'Email sinh viên (vd: nama@huflit.edu.vn)',
                icon: Icons.mail_outline_rounded,
                enabled: !controller.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: emailValidator,
              ),
              SizedBox(height: gap),
              _AnimatedAuthField(
                controller: studentIdController,
                hintText: 'Mã số sinh viên',
                icon: Icons.badge_outlined,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.next,
                validator: studentIdValidator,
              ),
              SizedBox(height: gap),
              _AnimatedAuthField(
                controller: phoneController,
                hintText: 'Số điện thoại',
                icon: Icons.phone_outlined,
                enabled: !controller.isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: phoneValidator,
              ),
              SizedBox(height: gap),
              _AnimatedAuthField(
                controller: passwordController,
                hintText: 'Mật khẩu',
                icon: Icons.lock_outline_rounded,
                enabled: !controller.isLoading,
                obscureText: hidePassword,
                textInputAction: TextInputAction.next,
                validator: passwordValidator,
                onChanged: onPasswordChanged,
                suffixIcon: _PasswordButton(
                  hidden: hidePassword,
                  enabled: !controller.isLoading,
                  onPressed: onTogglePassword,
                ),
              ),
              SizedBox(height: gap),
              _AnimatedAuthField(
                controller: confirmPasswordController,
                hintText: 'Nhập lại mật khẩu',
                icon: Icons.lock_outline_rounded,
                enabled: !controller.isLoading,
                obscureText: hideConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: confirmPasswordValidator,
                onSubmitted: (_) => onSubmit(),
                suffixIcon: _PasswordButton(
                  hidden: hideConfirmPassword,
                  enabled: !controller.isLoading,
                  onPressed: onToggleConfirmPassword,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 190),
                child: controller.errorMessage == null
                    ? const SizedBox.shrink()
                    : Container(
                        margin: const EdgeInsets.only(top: 13),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 19),
              _GradientRegisterButton(
                loading: controller.isLoading,
                onPressed: onSubmit,
              ),
              const SizedBox(height: 17),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: controller.isLoading ? null : onOpenLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: dark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                    child: const Text(
                      'Đăng nhập',
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
}

class _AnimatedAuthField extends StatefulWidget {
  const _AnimatedAuthField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.enabled,
    required this.textInputAction,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool enabled;
  final TextInputAction textInputAction;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_AnimatedAuthField> createState() => _AnimatedAuthFieldState();
}

class _AnimatedAuthFieldState extends State<_AnimatedAuthField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: focused
            ? (dark ? AppColors.surfaceSoftDark : Colors.white)
            : (dark ? AppColors.fieldDark : AppColors.field),
        borderRadius: BorderRadius.circular(17),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: dark ? 0.24 : 0.10,
                  ),
                  blurRadius: 13,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: dark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
          prefixIcon: Icon(
            widget.icon,
            size: 21,
            color: focused
                ? (dark ? AppColors.primaryLight : AppColors.primary)
                : (dark ? AppColors.textTertiaryDark : AppColors.textTertiary),
          ),
          suffixIcon: widget.suffixIcon,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 13,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: dark ? AppColors.dividerDark : AppColors.divider,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: dark ? AppColors.dividerDark : AppColors.divider,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: dark ? AppColors.primaryLight : AppColors.primary,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: AppColors.error, width: 1.4),
          ),
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 11.5,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class _PasswordButton extends StatelessWidget {
  const _PasswordButton({
    required this.hidden,
    required this.enabled,
    required this.onPressed,
  });

  final bool hidden;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: enabled ? onPressed : null,
      splashRadius: 18,
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: dark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
    );
  }
}

class _GradientRegisterButton extends StatelessWidget {
  const _GradientRegisterButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          height: 53,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: loading
                  ? [
                      AppColors.primary.withValues(alpha: 0.55),
                      AppColors.primaryLight.withValues(alpha: 0.55),
                    ]
                  : const [AppColors.primaryDark, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.23),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('register-loading'),
                      height: 21,
                      width: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.3,
                      ),
                    )
                  : const Text(
                      'ĐĂNG KÝ',
                      key: ValueKey('register-label'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterWaveClipper extends CustomClipper<Path> {
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
  bool shouldReclip(covariant _RegisterWaveClipper oldClipper) => false;
}
