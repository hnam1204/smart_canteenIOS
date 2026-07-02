import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'screens/smart_canteen/main_shell_screen.dart';
import 'screens/smart_canteen/payment_screen.dart';
import 'screens/smart_canteen/order_history/order_history_screen.dart';
import 'screens/smart_canteen/qr_pickup/order_model.dart' as pickup;
import 'screens/smart_canteen/qr_pickup/qr_pickup_screen.dart';
import 'screens/smart_canteen/vouchers/my_vouchers_screen.dart';
import 'screens/smart_canteen/promotion/promotion_screen.dart';

bool firebaseAvailable = false;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () async {
      await AppConfig.initialize();
      try {
        final options = DefaultFirebaseOptions.maybeCurrentPlatform;
        if (options == null) {
          throw StateError(
            'Firebase configuration is unavailable on this platform.',
          );
        }
        await Firebase.initializeApp(options: options);
        try {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        } on Object catch (error) {
          debugPrint('Firestore cache settings skipped: $error');
        }
        firebaseAvailable = true;
        await AppCheckService.activateForRelease();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
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
    },
    (error, stack) {
      debugPrint('Uncaught app error: $error');
      debugPrintStack(stackTrace: stack);
    },
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
          case '/menu':
            return AppPageTransition<void>(
              builder: (_) => const MainShellScreen(initialIndex: 1),
            );
          case '/cart':
            return AppPageTransition<void>(
              builder: (_) => const MainShellScreen(initialIndex: 2),
            );
          case '/payment':
            return AppPageTransition<void>(
              builder: (_) => const PaymentScreen(),
            );
          case '/order-history':
            return AppPageTransition<void>(
              builder: (_) => const OrderHistoryScreen(),
            );
          case '/qr-pickup':
            final args = settings.arguments;
            var orderId = '';
            pickup.OrderModel? previewOrder;
            if (args is String) {
              orderId = args;
            } else if (args is Map) {
              final nested = args['data'] is Map ? args['data'] as Map : null;
              final rawOrderId =
                  args['orderId'] ??
                  args['referenceId'] ??
                  nested?['orderId'] ??
                  args['orderCode'] ??
                  nested?['orderCode'];
              final normalizedOrderId = rawOrderId?.toString().trim() ?? '';
              if (normalizedOrderId.isNotEmpty) {
                orderId = normalizedOrderId;
              }
              final rawPreviewOrder = args['previewOrder'];
              if (rawPreviewOrder is pickup.OrderModel) {
                previewOrder = rawPreviewOrder;
              }
            }
            return AppPageTransition<void>(
              builder: (_) =>
                  QRPickupScreen(orderId: orderId, previewOrder: previewOrder),
            );
          case '/vouchers':
            return AppPageTransition<void>(
              builder: (_) => const MyVouchersScreen(),
            );
          case '/promotions':
            return AppPageTransition<void>(
              builder: (_) => const PromotionScreen(),
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
