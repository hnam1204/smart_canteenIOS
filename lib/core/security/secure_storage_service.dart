import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _expiresAtKey = 'auth.expires_at';
  static const _fcmTokenKey = 'messaging.fcm_token';

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'vn.edu.huflit.smartcanteen',
  );
  static const _androidOptions = AndroidOptions();

  final FlutterSecureStorage _storage;

  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await Future.wait([
      _write(_accessTokenKey, accessToken),
      _write(_refreshTokenKey, refreshToken),
      _write(_expiresAtKey, expiresAt.toUtc().toIso8601String()),
    ]);
  }

  Future<String?> readAccessToken() => _read(_accessTokenKey);

  Future<String?> readRefreshToken() => _read(_refreshTokenKey);

  Future<DateTime?> readExpiresAt() async {
    final raw = await _read(_expiresAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> writeFcmToken(String value) => _write(_fcmTokenKey, value);

  Future<String?> readFcmToken() => _read(_fcmTokenKey);

  Future<void> clearSession() async {
    await Future.wait([
      _delete(_accessTokenKey),
      _delete(_refreshTokenKey),
      _delete(_expiresAtKey),
    ]);
  }

  Future<void> clearAll() =>
      _storage.deleteAll(iOptions: _iosOptions, aOptions: _androidOptions);

  Future<void> _write(String key, String value) => _storage.write(
    key: key,
    value: value,
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );

  Future<String?> _read(String key) =>
      _storage.read(key: key, iOptions: _iosOptions, aOptions: _androidOptions);

  Future<void> _delete(String key) => _storage.delete(
    key: key,
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );
}
