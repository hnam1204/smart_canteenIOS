enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromValue(String value) {
    return switch (value.toLowerCase()) {
      'development' || 'dev' => AppEnvironment.development,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.production,
    };
  }
}
