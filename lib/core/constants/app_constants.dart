class AppConstants {
  // API
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const String baseUrl = 'https://mistech.up.railway.app/api';
  // static const String baseUrl = 'http://192.168.0.228:3000/api';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // App Info
  static const String appName = 'MiSTech';
  static const String appTagline = 'Cerdas Hadapi Bencana, Selamatkan Sesama';
  static const String appVersion = '1.0.0';

  // Endpoints
  static const String disastersEndpoint = '/disasters';
  static const String disasterDetailEndpoint = '/disasters';
  static const String videosEndpoint = '/videos';
  static const String articlesEndpoint = '/articles';
  static const String categoriesEndpoint = '/categories';

  // Storage Keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserName = 'user_name';
  static const String keyUserLevel = 'user_level';
  static const String keyUserXP = 'user_xp';

  // Disaster Phase
  static const String praBencana = 'pra';
  static const String saatBencana = 'saat';
  static const String pascaBencana = 'pasca';

  // Animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(seconds: 3);
}
