/// Where the app finds the ASP.NET API.
///
/// By default the app uses the team's shared dev address, a Dev Tunnel to the
/// API running on one laptop (see run-supaclean.ps1), so a plain
/// `flutter run` works. It only answers while that laptop has the API and the
/// tunnel running, and the tunnel expires after about 30 days; when it does,
/// update [defaultBaseUrl].
///
/// To use another API, for example one on your own laptop for a phone on the
/// same Wi-Fi, pass its address when running or building:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.20:5000
class ApiConfig {
  static const String defaultBaseUrl =
      'https://6v214f84-5238.inc1.devtunnels.ms';

  /// Not final so that tests can set it to '' and stay offline.
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static bool get isConfigured => baseUrl.isNotEmpty;
}

/// SupaClean's bank details shown on the Upload Proof screen. Fill these in;
/// while they are empty the screen simply hides the bank details card.
class PaymentConfig {
  static const String bankName = '';
  static const String accountHolder = '';
  static const String accountNumber = '';
  static const String branchCode = '';

  static bool get hasBankDetails =>
      bankName.isNotEmpty && accountNumber.isNotEmpty;
}
