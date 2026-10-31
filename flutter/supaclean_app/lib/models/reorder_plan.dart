import '../viewmodels/service_viewmodel.dart';
import 'laundry_order.dart';

/// What "Reorder" puts into Place Order: the same items and quantities as a
/// finished order, on today's prices and only where they can still be ordered.
class ReorderPlan {
  const ReorderPlan({
    required this.category,
    required this.quantities,
    required this.unavailable,
    this.pickupOption,
    this.deliveryOption,
  });

  /// The service category the items belong to. Null when none of the order's
  /// items can be ordered any more.
  final String? category;

  /// Item name to how many, for the items that can be ordered again.
  final Map<String, int> quantities;

  /// Items from the old order that are switched off, no longer offered, or
  /// belong to another category (a Place Order holds one category at a time).
  final List<String> unavailable;

  /// The pickup and return choices of the old order, as Place Order names
  /// them. Null when the server did not say.
  final String? pickupOption;
  final String? deliveryOption;

  bool get canReorder => category != null && quantities.isNotEmpty;

  List<String> get itemNames => quantities.keys.toList();

  // The server words these "Home pickup" or "Drop-off at depot: Mimosa Mall".
  static String? _pickup(String method) {
    final text = method.toLowerCase();
    if (text.startsWith('home')) return 'At my address';
    if (text.startsWith('drop')) return 'Drop off at depot';
    return null;
  }

  static String? _delivery(String method) {
    final text = method.toLowerCase();
    if (text.startsWith('home')) return 'Deliver to me';
    if (text.startsWith('collect')) return 'Collect at depot';
    return null;
  }

  static ReorderPlan of(LaundryOrder order, List<ServiceCategory> services) {
    String key(String name) => name.trim().toLowerCase();

    // How many of the order's items each category could still serve.
    final wanted = {for (final line in order.items) key(line.name): line};
    ServiceCategory? best;
    var bestCount = 0;
    for (final category in services) {
      final count = category.items
          .where((item) => item.isAvailable && wanted.containsKey(key(item.name)))
          .length;
      if (count > bestCount) {
        best = category;
        bestCount = count;
      }
    }

    final quantities = <String, int>{};
    if (best != null) {
      for (final item in best.items.where((item) => item.isAvailable)) {
        final line = wanted[key(item.name)];
        if (line != null) quantities[item.name] = line.quantity;
      }
    }

    final taken = {for (final name in quantities.keys) key(name)};
    final unavailable = [
      for (final line in order.items)
        if (!taken.contains(key(line.name))) line.name,
    ];

    return ReorderPlan(
      category: best?.name,
      quantities: quantities,
      unavailable: unavailable,
      pickupOption: _pickup(order.pickupMethod),
      deliveryOption: _delivery(order.returnMethod),
    );
  }
}
