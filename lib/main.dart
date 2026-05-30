import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'firebase/app_check_service.dart';
import 'firebase/firebase_messaging_handler.dart';
import 'services/notification_service.dart' as push;
import 'core/navigation/app_page_transition.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';

bool firebaseAvailable = false;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.initialize();
  try {
    final options = DefaultFirebaseOptions.maybeCurrentPlatform;
    if (options == null) {
      throw StateError('Firebase configuration is unavailable on this platform.');
    }
    await Firebase.initializeApp(options: options);
    firebaseAvailable = true;
    await AppCheckService.activateForRelease();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await push.NotificationService.instance.initialize();
    await push.NotificationService.instance.requestPermission();
  } on Object catch (error) {
    firebaseAvailable = false;
    debugPrint('Firebase unavailable: $error');
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: const SmartCanteenApp(),
    ),
  );
}

class SmartCanteenApp extends StatelessWidget {
  const SmartCanteenApp({super.key, this.authStateChanges});

  final Stream<User?>? authStateChanges;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? false;
    return MaterialApp(
      title: 'Smart Canteen',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: !firebaseAvailable && authStateChanges == null
          ? const _FirebaseUnavailableScreen()
          : StreamBuilder<User?>(
              stream:
                  authStateChanges ?? FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return snapshot.hasData
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return AppPageTransition<void>(builder: (_) => const HomeScreen());
          case '/login':
            return AppPageTransition<void>(builder: (_) => const LoginScreen());
          case '/register':
            return AppPageTransition<void>(
              builder: (_) => const RegisterScreen(),
            );
          case '/forgot-password':
            return AppPageTransition<void>(
              builder: (_) => const ForgotPasswordScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}

class _FirebaseUnavailableScreen extends StatelessWidget {
  const _FirebaseUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 52),
                SizedBox(height: 16),
                Text(
                  'Không thể kết nối dịch vụ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Firebase chưa được cấu hình cho thiết bị này. Vui lòng '
                  'kiểm tra cấu hình ứng dụng.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
