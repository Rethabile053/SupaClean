import '../models/user_model.dart';
import 'address_book.dart';
import 'order_api.dart';

/// Makes sure everyone who signs in to the app is also a customer on the
/// server (a row in the Users table marked Customer, and one in Customers),
/// even before they place an order.
class CustomerSync {
  const CustomerSync._();

  static String? _doneFor;

  /// Creates the customer on the server if it is not there yet. Quiet: the
  /// app carries on if the server cannot be reached, and tries again the
  /// next time. Does nothing twice for the same person in one run.
  static Future<void> ensure(
    UserModel? user, {
    OrderApi? api,
    String Function()? savedAddress,
  }) async {
    final email = user?.email.trim() ?? '';
    if (user == null || email.isEmpty || _doneFor == email) return;

    final client = api ?? OrderApi();
    if (!client.isConfigured) return;

    try {
      await client.ensureCustomer(
        fullName: user.fullName,
        email: email,
        phone: user.phoneNumber,
        address: (savedAddress ?? () => AddressBook.load().selected)(),
      );
      _doneFor = email;
    } catch (_) {
      // Try again next time.
    }
  }

  /// Forgets who was synced (used by tests).
  static void reset() => _doneFor = null;
}
