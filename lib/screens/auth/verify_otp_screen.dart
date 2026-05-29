import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/utils/app_feedback.dart';
import '../../services/otp_service.dart';
import 'password_reset_widgets.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.otpService,
  });

  final String email;
  final OtpService otpService;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 60;
  bool _loading = false;
  bool _resending = false;
  bool _showCodeError = false;

  String get _otp => _controllers.map((controller) => controller.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    if (mounted && _seconds != 60) {
      setState(() => _seconds = 60);
    } else {
      _seconds = 60;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _onChanged(int index, String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 1) {
      _fillPastedCode(index, digits);
      return;
    }
    if (_showCodeError && digits.isNotEmpty) {
      setState(() => _showCodeError = false);
    }
    if (digits.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _fillPastedCode(int start, String digits) {
    var target = start;
    for (final digit in digits.split('')) {
      if (target >= 6) break;
      _controllers[target].value = TextEditingValue(
        text: digit,
        selection: const TextSelection.collapsed(offset: 1),
      );
      target++;
    }
    if (_showCodeError) setState(() => _showCodeError = false);
    _focusNodes[(target.clamp(1, 6) - 1)].requestFocus();
  }

  void _deletePrevious(int index) {
    if (_controllers[index].text.isNotEmpty) return;
    if (index == 0) return;
    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
  }

  Future<void> _verifyOtp() async {
    if (_loading || _resending) return;
    if (_otp.length != 6) {
      setState(() => _showCodeError = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await widget.otpService.verifyOtp(email: widget.email, otp: _otp);
      if (!mounted) return;
      showAppSnackBar(context, 'Xác thực OTP thành công.');
      AppNavigator.push<void>(
        context,
        builder: (_) => ResetPasswordScreen(
          email: widget.email,
          verificationCode: _otp,
          otpService: widget.otpService,
        ),
      );
    } on OtpApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Không thể xác thực OTP. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_seconds > 0 || _resending || _loading) return;
    setState(() => _resending = true);
    try {
      await widget.otpService.sendOtp(widget.email);
      if (!mounted) return;
      setState(() {
        for (final controller in _controllers) {
          controller.clear();
        }
      });
      _startCountdown();
      _focusNodes.first.requestFocus();
      showAppSnackBar(context, 'Đã gửi lại mã OTP.');
    } on OtpApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Không thể gửi lại mã OTP. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _resending = false);
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
      title: 'Xác thực OTP',
      subtitle: 'Nhập mã OTP vừa gửi đến\n${widget.email}',
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 72),
          Row(
            children: List.generate(11, (position) {
              if (position.isOdd) return const SizedBox(width: 7);
              final index = position ~/ 2;
              return Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controllers[index].text.isEmpty) {
                      _deletePrevious(index);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: !_loading,
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    autofillHints: index == 0
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    onChanged: (value) => _onChanged(index, value),
                    onSubmitted: (_) {
                      if (index == 5) _verifyOtp();
                    },
                    textInputAction: index == 5
                        ? TextInputAction.done
                        : TextInputAction.next,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _showCodeError
                              ? AppColors.error
                              : AppColors.divider,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: _showCodeError
                ? const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Vui lòng nhập đủ 6 số OTP.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 38),
          Center(
            child: _seconds > 0
                ? Text.rich(
                    TextSpan(
                      text: 'Gửi lại mã sau ',
                      style: const TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: '00:${_seconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : TextButton(
                    onPressed: _resending ? null : _resendOtp,
                    child: Text(_resending ? 'Đang gửi...' : 'Gửi lại mã OTP'),
                  ),
          ),
          const SizedBox(height: 38),
          ResetActionButton(
            label: 'Xác nhận OTP',
            loading: _loading,
            onPressed: _verifyOtp,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}
