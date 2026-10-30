import 'dart:async';

import 'package:flutter/material.dart';
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
    this.refreshEvery = const Duration(seconds: 30),
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

  /// [base] with the server's prices, descriptions and availability applied,
  /// and the services the admin added (ones the app has no built-in item for)
  /// placed under the category the admin gave them. A category the app does
  /// not have yet gets its own heading.
  List<ServiceCategory> apply(List<ServiceCategory> base) {
    final live = _live;
    if (live == null) return base;

    final known = {
      for (final category in base)
        for (final item in category.items) _key(item.name),
    };

    // Admin-added services, grouped by category (case and spacing ignored).
    final added = <String, List<ApiService>>{};
    final addedNames = <String, String>{};
    for (final service in live.values) {
      if (known.contains(_key(service.name))) continue;
      final category = service.category?.trim() ?? '';
      if (category.isEmpty) continue; // nowhere to show it
      (added[_key(category)] ??= []).add(service);
      addedNames.putIfAbsent(_key(category), () => category);
    }

    List<ServiceItem> itemsFor(List<ApiService>? services) => [
          for (final service in [...?services]
            ..sort((a, b) => a.name.compareTo(b.name)))
            ServiceItem(
              name: service.name.trim(),
              price: service.price,
              description: service.description.trim().isEmpty
                  ? 'SupaClean service.'
                  : service.description.trim(),
              isAvailable: service.isActive,
            ),
        ];

    final result = <ServiceCategory>[
      for (final category in base)
        () {
          final extra = itemsFor(added.remove(_key(category.name)));
          final items = [..._items(category, live), ...extra];
          return ServiceCategory(
            name: category.name,
            description: category.description,
            icon: category.icon,
            items: items,
            startingPrice: category.startingPrice == null && extra.isEmpty
                ? null
                : _cheapest(items) ?? category.startingPrice,
          );
        }(),
    ];

    // Categories the admin made up.
    for (final entry in added.entries) {
      final items = itemsFor(entry.value);
      result.add(ServiceCategory(
        name: addedNames[entry.key]!,
        description: 'Services from SupaClean.',
        icon: Icons.cleaning_services,
        items: items,
        startingPrice: _cheapest(items),
      ));
    }
    return result;
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

  /// The lowest price among the services on offer, or null when none has one.
  double? _cheapest(List<ServiceItem> items) {
    final prices = [
      for (final item in items)
        if (item.isAvailable && item.price > 0) item.price,
    ];
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }
}

/// For a screen that shows services: asks for the server's list when it opens,
/// keeps asking while it stays open, and redraws when the list changes. So a
/// price, a switched-off service or a new service the admin saves shows up
/// within about half a minute, without reopening the screen.
mixin ServiceCatalogueWatcher<T extends StatefulWidget> on State<T> {
  /// How often an open screen checks again.
  static const Duration checkEvery = Duration(seconds: 30);

  Timer? _catalogueTimer;

  @override
  void initState() {
    super.initState();
    ServiceCatalogue.instance.addListener(_changed);
    ServiceCatalogue.instance.refresh();
    _catalogueTimer = Timer.periodic(
      checkEvery,
      (_) => ServiceCatalogue.instance.refresh(force: true),
    );
  }

  @override
  void dispose() {
    _catalogueTimer?.cancel();
    ServiceCatalogue.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(onCatalogueChanged);
  }

  /// Runs inside setState when the list changes.
  void onCatalogueChanged() {}
}
