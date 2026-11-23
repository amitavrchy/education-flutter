/// Build-time configuration, passed with `--dart-define-from-file=config/dev.json`.
///
/// Android emulator reaches the host machine's localhost at 10.0.2.2;
/// iOS simulator and desktop use localhost directly.
abstract final class Env {
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'EduMentor AI');

  /// Base URL of the ShikkhaAI backend, including the version prefix.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  /// true = local mock repositories, false = call [apiBaseUrl].
  static const bool useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);
}
