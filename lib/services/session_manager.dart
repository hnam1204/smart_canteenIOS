import '../core/security/secure_storage_service.dart';

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(
    DateTime.now().toUtc().add(const Duration(seconds: 30)),
  );
}

typedef RefreshSession = Future<SessionTokens?> Function(String refreshToken);

class SessionManager {
  SessionManager({SecureStorageService? storage})
    : _storage = storage ?? SecureStorageService();

  final SecureStorageService _storage;

  Future<void> save(SessionTokens tokens) => _storage.writeSession(
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresAt: tokens.expiresAt,
  );

  Future<SessionTokens?> restore() async {
    final values = await Future.wait([
      _storage.readAccessToken(),
      _storage.readRefreshToken(),
      _storage.readExpiresAt(),
    ]);
    final accessToken = values[0] as String?;
    final refreshToken = values[1] as String?;
    final expiresAt = values[2] as DateTime?;
    if (accessToken == null || refreshToken == null || expiresAt == null) {
      return null;
    }
    return SessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Future<String?> validAccessToken({RefreshSession? refresh}) async {
    final session = await restore();
    if (session == null) return null;
    if (!session.isExpired) return session.accessToken;
    if (refresh == null) {
      await clear();
      return null;
    }
    final refreshed = await refresh(session.refreshToken);
    if (refreshed == null) {
      await clear();
      return null;
    }
    await save(refreshed);
    return refreshed.accessToken;
  }

  Future<void> clear() => _storage.clearSession();
}
