import 'package:flutter/widgets.dart';
import '../viewmodels/service_viewmodel.dart';
import 'order_api.dart';

/// The server's price list, laid over the categories the app draws.
///
/// The app owns how services are grouped and pictured. The server (and so the
/// admin) owns what each item costs, how it is described and whether it is
/// offered. Until the list has loaded, or if it cannot be loaded, the app
/// shows its built-in list, so the screens are never empty.
class ServiceCatalogue extends ChangeNotifier {
  ServiceCatalogue({
    Future<List<ApiService>> Function()? fetch,
    this.refreshEvery = const Duration(minutes: 1),
  }) : _fetch = fetch ?? (() => OrderApi().services(includeInactive: true));

  /// The one the screens share.
  static final ServiceCatalogue instance = ServiceCatalogue();

  final Future<List<ApiService>> Function() _fetch;

  /// How long a loaded list is trusted before screens ask again.
  final Duration refreshEvery;

  Map<String, ApiService>? _live;
  DateTime? _loadedAt;
  Future<void>? _loading;

  /// True once the server's list has been loaded.
  bool get isLive => _live != null;

  static String _key(String name) => name.trim().toLowerCase();

  /// Loads the server's list. Does nothing when a fresh copy is already held
  /// or a load is under way, and keeps what it has if the server can't be
  /// reached.
  Future<void> refresh({bool force = false}) {
    final loadedAt = _loadedAt;
    if (!force &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < refreshEvery) {
      return Future.value();
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final list = await _fetch();
      // An empty list is more likely a server problem than an empty menu.
      if (list.isEmpty) return;
      _live = {for (final service in list) _key(service.name): service};
      _loadedAt = DateTime.now();
      notifyListeners();
    } catch (_) {
      // Keep showing what we have.
    }
  }

  /// Shows [list] as the server's answer without asking the server (used by
  /// tests).
  @visibleForTesting
  void useForTest(List<ApiService> list) {
    _live = {for (final service in list) _key(service.name): service};
    _loadedAt = DateTime.now();
    notifyListeners();
  }

  /// Forgets the loaded list (used by tests).
  @visibleForTesting
  void reset() {
    _live = null;
    _loadedAt = null;
    _loading = null;
  }

  /// [base] with the server's prices, descriptions and availability applied.
  List<ServiceCategory> apply(List<ServiceCategory> base) {
    final live = _live;
    if (live == null) return base;

    return [
      for (final category in base)
        ServiceCategory(
          name: category.name,
          description: category.description,
          icon: category.icon,
          items: _items(category, live),
          startingPrice: category.startingPrice == null
              ? null
              : _startingPrice(category, live) ?? category.startingPrice,
        ),
    ];
  }

  List<ServiceItem> _items(
    ServiceCategory category,
    Map<String, ApiService> live,
  ) {
    return [
      for (final item in category.items)
        if (live[_key(item.name)] case final service?)
          ServiceItem(
            name: item.name,
            price: service.price,
            description: service.description.trim().isEmpty
                ? item.description
                : service.description.trim(),
            isAvailable: service.isActive,
          )
        // Priced after assessment, so the server has no price for it.
        else if (item.price == 0)
          item,
      // Anything else the server doesn't list is not on offer right now.
    ];
  }

  double? _startingPrice(
    ServiceCategory category,
    Map<String, ApiService> live,
  ) {
    final prices = [
      for (final item in category.items)
        if (live[_key(item.name)] case final service?)
          if (service.isActive && service.price > 0) service.price,
    ];
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }
}

/// For a screen that shows services: asks for the server's list when it opens
/// and redraws when the list arrives or changes.
mixin ServiceCatalogueWatcher<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ServiceCatalogue.instance.addListener(_changed);
    ServiceCatalogue.instance.refresh();
  }

  @override
  void dispose() {
    ServiceCatalogue.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(onCatalogueChanged);
  }

  /// Runs inside setState when the list changes.
  void onCatalogueChanged() {}
}
