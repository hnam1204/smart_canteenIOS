import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_page_transition.dart';
import '../../core/theme/text_styles.dart';
import '../smart_canteen/main_shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _firebaseUnavailable = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 1450), () {
      if (!mounted) return;
      if (Firebase.apps.isEmpty) {
        setState(() => _firebaseUnavailable = true);
        return;
      }
      Navigator.of(context).pushReplacement(
        AppPageTransition<void>(builder: (_) => const MainShellScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseUnavailable) return const _SplashFirebaseUnavailable();
    final reveal = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: reveal,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(reveal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 112,
                      width: 112,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.13),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/logos/smart_canteen.png'),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Smart Canteen',
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đặt món nhanh, nhận món đúng giờ',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                    const SizedBox(height: 38),
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashFirebaseUnavailable extends StatelessWidget {
  const _SplashFirebaseUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Không thể mở Smart Canteen',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Firebase chưa sẵn sàng trên thiết bị này. Vui lòng kiểm tra cấu hình rồi thử lại.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Quay lại'),
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
