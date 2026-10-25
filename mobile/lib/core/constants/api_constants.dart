class ApiConstants {
  // Configurable base URL: defaults to localhost:8000 (or 10.0.2.2 for Android emulator)
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // Toggle between MockRepository and RealApiRepository
  // When false, connects to local FastAPI backend; when true, runs with in-memory mock data
  static bool useMockData = false;

  // Storage Keys
  static const String keyAccessToken = 'chauffeurx_access_token';
  static const String keyRefreshToken = 'chauffeurx_refresh_token';
  static const String keyUserRole = 'chauffeurx_user_role';
  static const String keyOnboardingCompleted = 'chauffeurx_onboarding_done';
}
