import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in customer's saved pickup addresses and the one in use.
class SavedAddresses {
  const SavedAddresses({this.all = const [], this.selected = ''});

  final List<String> all;

  /// The address pre-filled on Choose Date & Time ('' when none is chosen).
  final String selected;
}

/// Keeps a customer's addresses in their Supabase account (user metadata), so
/// they follow the customer to a new phone and need no extra table.
///
/// Every method is safe to call when nobody is signed in or Supabase is
/// unreachable: it quietly does nothing, and the app just asks for the
/// address as before.
class AddressBook {
  const AddressBook._();

  static const _listKey = 'addresses';
  static const _selectedKey = 'selected_address';

  static User? get _user {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null; // Supabase not started (e.g. in widget tests).
    }
  }

  static SavedAddresses load() {
    final meta = _user?.userMetadata ?? const {};
    final all = [
      for (final item in (meta[_listKey] as List<dynamic>? ?? const []))
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
    var selected = (meta[_selectedKey] as String?)?.trim() ?? '';
    if (!all.contains(selected)) selected = all.isEmpty ? '' : all.first;
    return SavedAddresses(all: all, selected: selected);
  }

  /// Saves [address] if it is new, and makes it the selected one.
  static Future<SavedAddresses> addAndSelect(String address) async {
    final value = address.trim();
    final current = load();
    if (value.isEmpty) return current;
    final all = [...current.all];
    if (!all.contains(value)) all.add(value);
    return _save(all, value);
  }

  static Future<SavedAddresses> select(String address) {
    final current = load();
    return _save(current.all, address);
  }

  static Future<SavedAddresses> remove(String address) {
    final current = load();
    final all = [...current.all]..remove(address);
    final selected = current.selected == address
        ? (all.isEmpty ? '' : all.first)
        : current.selected;
    return _save(all, selected);
  }

  static Future<SavedAddresses> _save(
    List<String> all,
    String selected,
  ) async {
    if (_user == null) return SavedAddresses(all: all, selected: selected);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {_listKey: all, _selectedKey: selected}),
      );
    } catch (error) {
      debugPrint('Could not save addresses: $error');
      rethrow;
    }
    return SavedAddresses(all: all, selected: selected);
  }
}
