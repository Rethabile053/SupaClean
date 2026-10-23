/// Where the app finds the ASP.NET API.
///
/// Pass the address when running or building, e.g. for a phone on the same
/// Wi-Fi as the laptop running the API:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.20:5000
///
/// Leave it out and the app still works, but ordering and live notifications
/// say that the server is not set up.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

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
