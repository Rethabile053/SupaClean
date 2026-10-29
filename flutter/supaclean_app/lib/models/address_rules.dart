/// What counts as a usable address for home pickup and delivery.
class AddressRules {
  const AddressRules._();

  // Areas where home pickup and delivery are supported.
  // Both spellings of Botshabelo are accepted.
  static const List<String> supportedAreas = [
    'bloemfontein',
    'botshabelo',
    'botsabelo',
    'thaba nchu',
    'thaba-nchu',
  ];

  static const invalidMessage =
      'Please enter a valid address, including your street or stand number, suburb and town.';

  static const unsupportedAreaMessage =
      'Home pickup and delivery are available only in Bloemfontein, Botshabelo and Thaba Nchu. Please include one of these areas in your address or choose a depot.';

  /// Checks whether the address looks like a usable address.
  /// This does not confirm that the property actually exists.
  static bool looksValid(String address) {
    final cleaned = address.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.length < 8) return false;

    final words = cleaned
        .split(RegExp(r'[,\s]+'))
        .where(
          (word) =>
              word.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').isNotEmpty,
        )
        .toList();

    if (words.length < 3) return false;

    final letters = cleaned.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 5) return false;

    final hasNumber = RegExp(r'\d').hasMatch(cleaned);
    final lower = cleaned.toLowerCase();

    final hasAddressClue = [
      'street',
      ' st ',
      'road',
      ' rd ',
      'avenue',
      ' ave ',
      'drive',
      ' dr ',
      'lane',
      'crescent',
      'cres',
      'plot',
      'stand',
      'erf',
      'house',
      'section',
      'block',
      'extension',
      'ext',
      'farm',
      'unit',
      'suburb',
      ...supportedAreas,
    ].any((clue) => lower.contains(clue));

    return hasNumber || hasAddressClue;
  }

  /// Checks whether the address contains a supported area.
  static bool isSupportedArea(String address) {
    final normalized =
        address.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return supportedAreas.any(normalized.contains);
  }

  /// The message to show for an address that can't be used for home pickup
  /// or delivery, or null when it is fine.
  static String? problem(String address) {
    if (!looksValid(address)) return invalidMessage;
    if (!isSupportedArea(address)) return unsupportedAreaMessage;
    return null;
  }
}
