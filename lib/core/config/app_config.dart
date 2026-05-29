import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env.dart';

class AppConfig {
  AppConfig._();

  static const String _defaultApiBaseUrl = 'http://192.168.1.6:3000';
  static const int _defaultTimeoutSeconds = 15;

  static const _apiBaseOverride = String.fromEnvironment('API_BASE_URL');
  static const _environmentOverride = String.fromEnvironment('APP_ENV');
  static const _timeoutOverride = String.fromEnvironment('API_TIMEOUT_SECONDS');
  static const _firebaseWebVapidKeyOverride = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  static bool _initialized = false;
  static Uri _apiBaseUri = Uri.parse(_defaultApiBaseUrl);
  static Duration _requestTimeout = const Duration(
    seconds: _defaultTimeoutSeconds,
  );
  static AppEnvironment _environment = AppEnvironment.development;
  static String? _firebaseWebVapidKey;
  static Map<String, String> _fileValues = const {};

  static Future<void> initialize({
    String fileName = 'assets/config/production.env',
  }) async {
    if (_initialized) return;

    try {
      try {
        await dotenv.load(fileName: fileName);
        _fileValues = dotenv.env;
      } catch (error) {
        _fileValues = const {};
        debugPrint(
          'AppConfig warning: unable to load "$fileName"; using fallback '
          'configuration. $error',
        );
      }

      _environment = _parseEnvironment(
        _value(_environmentOverride, 'APP_ENV', 'development'),
      );
      _apiBaseUri = _parseApiBaseUrl(
        _value(_apiBaseOverride, 'API_BASE_URL', _defaultApiBaseUrl),
      );
      _requestTimeout = Duration(
        seconds: _parseTimeout(
          _value(
            _timeoutOverride,
            'API_TIMEOUT_SECONDS',
            '$_defaultTimeoutSeconds',
          ),
        ),
      );

      final vapidKey = _value(
        _firebaseWebVapidKeyOverride,
        'FIREBASE_WEB_VAPID_KEY',
        '',
      ).trim();
      _firebaseWebVapidKey = vapidKey.isEmpty ? null : vapidKey;

      _warnForInsecureProductionApi();
    } catch (error) {
      debugPrint(
        'AppConfig warning: configuration initialization failed; continuing '
        'with safe fallback values. $error',
      );
      _resetToFallback();
    } finally {
      _initialized = true;
    }
  }

  static Uri get apiBaseUri => _apiBaseUri;

  static Duration get requestTimeout => _requestTimeout;

  static AppEnvironment get environment => _environment;

  static bool get isProduction => environment == AppEnvironment.production;

  static String? get firebaseWebVapidKey => _firebaseWebVapidKey;

  static bool get initialized => _initialized;

  static String _value(String override, String key, String fallback) {
    if (override.trim().isNotEmpty) return override.trim();
    final fileValue = _fileValues[key]?.trim();
    return fileValue == null || fileValue.isEmpty ? fallback : fileValue;
  }

  static AppEnvironment _parseEnvironment(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized != 'development' &&
        normalized != 'dev' &&
        normalized != 'staging' &&
        normalized != 'stage' &&
        normalized != 'production' &&
        normalized != 'prod') {
      debugPrint(
        'AppConfig warning: unsupported APP_ENV "$value"; using development.',
      );
      return AppEnvironment.development;
    }
    if (normalized == 'prod') return AppEnvironment.production;
    return AppEnvironment.fromValue(normalized);
  }

  static Uri _parseApiBaseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      debugPrint(
        'AppConfig warning: invalid API_BASE_URL "$value"; using '
        '$_defaultApiBaseUrl.',
      );
      return Uri.parse(_defaultApiBaseUrl);
    }
    return uri;
  }

  static int _parseTimeout(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      debugPrint(
        'AppConfig warning: invalid API_TIMEOUT_SECONDS "$value"; using '
        '$_defaultTimeoutSeconds.',
      );
      return _defaultTimeoutSeconds;
    }
    return parsed.clamp(5, 60).toInt();
  }

  static void _warnForInsecureProductionApi() {
    if ((_environment == AppEnvironment.production || kReleaseMode) &&
        _apiBaseUri.scheme != 'https') {
      debugPrint(
        'AppConfig warning: HTTP API is configured for a production/release '
        'build. Use HTTPS before distribution.',
      );
    }
  }

  static void _resetToFallback() {
    _environment = AppEnvironment.development;
    _apiBaseUri = Uri.parse(_defaultApiBaseUrl);
    _requestTimeout = const Duration(seconds: _defaultTimeoutSeconds);
    _firebaseWebVapidKey = null;
    _fileValues = const {};
  }
}
