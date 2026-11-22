abstract final class AppConstants {
  static const String appNameBn = 'শিক্ষাAI';
  static const String tagline = 'বাংলাদেশের শিক্ষার্থীদের জন্য AI-চালিত শিক্ষা';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Keys used in secure storage.
abstract final class StorageKeys {
  static const String accessToken = 'auth.access_token';
  static const String refreshToken = 'auth.refresh_token';
  static const String user = 'auth.user';
}
