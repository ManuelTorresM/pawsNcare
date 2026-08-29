class AppConfig {
  /// Toggle for Demo Mode.
  /// Defaults to false for production (Firebase only).
  /// Can be set via compile-time flag: --dart-define=DEMO_MODE=true
  static bool isDemoMode = const bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );
}
