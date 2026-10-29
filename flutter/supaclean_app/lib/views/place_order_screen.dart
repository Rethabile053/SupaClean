
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supaclean/views/main_shell.dart';
import '../models/address_rules.dart';
import '../models/order_draft.dart';
import '../services/address_book.dart';
import '../services/checkout_service.dart';
import '../services/order_api.dart';
import '../services/service_catalogue.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_header.dart';
import 'date_time_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String category;
  final List<String> initialItems;

  /// Replaces the server call for the delivery areas (used by tests).
  final Future<List<({String id, String name, double fee})>> Function()?
      loadZones;

  const PlaceOrderScreen({
    super.key,
    required this.category,
    this.initialItems = const [],
    this.loadZones,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen>
    with ServiceCatalogueWatcher {
  final ServiceViewModel viewModel = ServiceViewModel();

  static const Color red = Color(0xFFEF3E46);
  static const Color background = Color(0xFFF7F8FA);
  static const Color dark = Color(0xFF202124);
  static const Color grey = Color(0xFF747982);
  static const Color border = Color(0xFFE6E8EC);

  // Home pickup and delivery are charged by area. This is the fee until the
  // customer's area is known (or if the server can't be reached).
  static const double _defaultHomeFee = 50.00;

  late String selectedCategory;

  /// Where we collect from and deliver to when the customer chooses home
  /// pickup or delivery. Starts as the address saved in My Addresses.
  String address = '';

  /// Delivery areas and their fees from the server. Null until loaded.
  List<({String id, String name, double fee})>? _zones;

  final Map<String, ServiceItem> selectedItems = {};
  final Map<String, int> quantities = {};

  String pickupOption = 'At my address';
  String deliveryOption = 'Deliver to me';

  // These coordinates are approximate and should be verified before release.
  static const List<Map<String, String>> depotLocations = [
    {
      'name': 'Mimosa Mall',
      'address':
          'Lower Retail Level, 131 Kellner Street, Brandwag, Bloemfontein, 9301',
      'latitude': '-29.1076497',
      'longitude': '26.2003417',
    },
    {
      'name': 'Fleurdal Mall',
      'address':
          'Kiosk 2C, Entrance 2, Fleurdal Mall, Vereeniging Drive, Fleurdal, Bloemfontein, 9301',
      'latitude': '-29.1582109',
      'longitude': '26.1912467',
    },
    {
      'name': 'Preller Square',
      'address':
          'Suite 19, First Floor, Preller Square Shopping Centre, Graaf Reinet Street, Dan Pienaar, Bloemfontein, 9301',
      'latitude': '-29.08777',
      'longitude': '26.21244',
    },
    {
      'name': 'Bloem Plaza',
      'address':
          'Corner Charlotte Maxeke and East Burger Streets, Bloemfontein, 9300',
      'latitude': '-29.11715',
      'longitude': '26.22289',
    },
    {
      'name': 'Main Factory - Hamilton',
      'address': '15 Piet Human Street, Hamilton, Bloemfontein, 9301',
      'latitude': '-29.183635',
      'longitude': '26.220301',
    },
    {
      'name': 'Botshabelo',
      'address': 'Centre Strand Street, Botshabelo, 9781',
      'latitude': '-29.2486',
      'longitude': '26.7160',
    },
    {
      'name': 'Thaba Nchu',
      'address': 'Main Street, Cornerstone Building, Thaba Nchu, 9780',
      'latitude': '-29.2153',
      'longitude': '26.8414',
    },
  ];

  String? selectedDropOffDepot;
  String? selectedCollectionDepot;

  Position? _userPosition;
  bool _isFindingNearest = false;
  String? _locationStatus;

  List<ServiceCategory> get services => viewModel.services;

  ServiceCategory get currentCategory => services.firstWhere(
        (service) => service.name == selectedCategory,
      );

  String getItemKey(ServiceItem item) => '$selectedCategory:${item.name}';

  double get subtotal {
    double amount = 0;
    for (final entry in selectedItems.entries) {
      amount += entry.value.price * (quantities[entry.key] ?? 0);
    }
    return amount;
  }

  bool get _homePickup => pickupOption == 'At my address';

  bool get _homeDelivery => deliveryOption == 'Deliver to me';

  /// The line under the Pickup and Delivery options when we go to the
  /// customer's address.
  String get _addressDetail =>
      address.isEmpty ? 'Tap to add your address' : address;

  /// The area the address is in, if it names one of our delivery areas.
  ({String id, String name, double fee})? _zoneFor(String text) {
    final normalized = CheckoutService.normalizeArea(text);
    for (final zone in _zones ?? const []) {
      if (normalized.contains(CheckoutService.normalizeArea(zone.name))) {
        return zone;
      }
    }
    return null;
  }

  /// What one home trip (pickup or delivery) costs for [text]'s area.
  double _homeFeeFor(String text) => _zoneFor(text)?.fee ?? _defaultHomeFee;

  double get pickupCost => _homePickup ? _homeFeeFor(address) : 0;

  double get deliveryCost => _homeDelivery ? _homeFeeFor(address) : 0;

  double get total => subtotal + pickupCost + deliveryCost;

  @override
  void initState() {
    super.initState();

    selectedCategory = services.any(
      (service) => service.name == widget.category,
    )
        ? widget.category
        : services.first.name;

    _addInitialItem(widget.initialItems);

    address = AddressBook.load().selected;
    _loadZones();
  }

  /// The server's prices arrived (or changed): keep the ticked items, but on
  /// their current price, and drop any that are no longer offered.
  @override
  void onCatalogueChanged() {
    for (final key in selectedItems.keys.toList()) {
      final name = selectedItems[key]!.name;
      ServiceItem? fresh;
      for (final category in services) {
        if (!key.startsWith('${category.name}:')) continue;
        for (final item in category.items) {
          if (item.name == name) fresh = item;
        }
      }
      if (fresh == null || !fresh.isAvailable) {
        selectedItems.remove(key);
        quantities.remove(key);
      } else {
        selectedItems[key] = fresh;
      }
    }
  }

  Future<void> _loadZones() async {
    try {
      final zones = widget.loadZones != null
          ? await widget.loadZones!()
          : await OrderApi().deliveryZones();
      if (mounted) setState(() => _zones = zones);
    } catch (_) {
      // Keep the default fee.
    }
  }

  // Ask for location permission and read the customer's current location.
  Future<bool> _findUserLocation({bool force = false}) async {
    if (_userPosition != null && !force) return true;

    if (mounted) {
      setState(() {
        _isFindingNearest = true;
        _locationStatus = null;
        if (force) _userPosition = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _locationStatus =
            'Location services are off. Turn them on to find the nearest depot.';
        return false;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _locationStatus =
            'Location permission was denied. You can still choose a depot manually.';
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        _locationStatus =
            'Location permission is blocked. Enable it in your device settings to find the nearest depot.';
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return false;

      setState(() {
        _userPosition = position;
        _locationStatus = null;
      });

      return true;
    } catch (_) {
      _locationStatus =
          'Could not get your location. Check your signal and try again, or choose a depot manually.';
      return false;
    } finally {
      if (mounted) {
        setState(() => _isFindingNearest = false);
      }
    }
  }

  double _distanceToDepot(Map<String, String> depot) {
    final position = _userPosition;
    if (position == null) return double.infinity;

    final latitude = double.tryParse(depot['latitude'] ?? '');
    final longitude = double.tryParse(depot['longitude'] ?? '');

    if (latitude == null || longitude == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
  }

  List<Map<String, String>> _sortedDepotLocations() {
    final locations = List<Map<String, String>>.from(depotLocations);

    if (_userPosition != null) {
      locations.sort(
        (first, second) =>
            _distanceToDepot(first).compareTo(_distanceToDepot(second)),
      );
    }

    return locations;
  }

  String _distanceLabel(Map<String, String> depot) {
    final metres = _distanceToDepot(depot);

    if (!metres.isFinite) return '';
    if (metres < 1000) return '${metres.round()} m away';

    return '${(metres / 1000).toStringAsFixed(1)} km away';
  }

  void _addInitialItem([List<String> names = const []]) {
    // An item the admin switched off cannot be ordered, so never pre-pick it.
    final items =
        currentCategory.items.where((item) => item.isAvailable).toList();
    final chosen = items.where((item) => names.contains(item.name)).toList();

    for (final item in chosen.isNotEmpty ? chosen : items.take(1)) {
      final key = getItemKey(item);
      selectedItems[key] = item;
      quantities[key] = 1;
    }
  }

  void _selectCategory(ServiceCategory service) {
    if (selectedCategory == service.name) return;

    setState(() {
      selectedCategory = service.name;
      selectedItems.clear();
      quantities.clear();
      _addInitialItem();
    });
  }

  void _addItem(ServiceItem item) {
    final key = getItemKey(item);

    setState(() {
      selectedItems[key] = item;
      quantities[key] = (quantities[key] ?? 0) + 1;
    });
  }

  void _changeQuantity(String key, int change) {
    setState(() {
      final newQuantity = (quantities[key] ?? 0) + change;

      if (newQuantity <= 0) {
        quantities.remove(key);
        selectedItems.remove(key);
      } else {
        quantities[key] = newQuantity;
      }
    });
  }

  String _shortName(String name) {
    switch (name) {
      case 'Dry Cleaning':
        return 'Dry Clean';
      case 'Bedding & Linen':
        return 'Bedding';
      case 'Other Special Services':
        return 'Other';
      default:
        return name;
    }
  }

  IconData _serviceIcon(String name) {
    switch (name) {
      case 'Wash & Fold':
        return Icons.local_laundry_service;
      case 'Dry Cleaning':
        return Icons.auto_awesome;
      case 'Ironing':
        return Icons.checkroom;
      case 'Bedding & Linen':
        return Icons.bed_outlined;
      case 'Shoe Cleaning':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.add;
    }
  }

  bool _isPerKg(ServiceItem item) =>
      item.name.toLowerCase().contains('per kg');

  void _showAddItems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: dark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentCategory.items.length,
                    itemBuilder: (context, index) {
                      final item = currentCategory.items[index];

                      return ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: dark,
                          ),
                        ),
                        subtitle: Text(
                          !item.isAvailable
                              ? 'Currently unavailable'
                              : item.price == 0
                                  ? 'Price confirmed after assessment'
                                  : 'R${item.price.toStringAsFixed(2)}'
                                      '${_isPerKg(item) ? '/kg' : ' each'}'
                                      '${item.isEstimated ? ' (estimated)' : ''}',
                          style: const TextStyle(fontSize: 12, color: grey),
                        ),
                        trailing: IconButton(
                          onPressed:
                              item.isAvailable ? () => _addItem(item) : null,
                          icon: Icon(
                            item.isAvailable
                                ? Icons.add_circle
                                : Icons.block,
                            color: item.isAvailable ? red : grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _chooseOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option),
                    trailing: Icon(
                      option == current
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: option == current ? red : grey,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSelected(option);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDepotPicker({required bool forDropOff}) async {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Checking your location to find the nearest depot…'),
            duration: Duration(seconds: 13),
          ),
        );
    }

    await _findUserLocation(force: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final selectedDepot =
        forDropOff ? selectedDropOffDepot : selectedCollectionDepot;

    final depot = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SafeArea(
            child: StatefulBuilder(
              builder: (sheetContext, setModalState) {
                final locations = _sortedDepotLocations();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              forDropOff
                                  ? 'Choose a drop-off depot'
                                  : 'Choose a collection depot',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: dark,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh location',
                            onPressed: _isFindingNearest
                                ? null
                                : () async {
                                    final locationFuture =
                                        _findUserLocation(force: true);

                                    await locationFuture;

                                    if (sheetContext.mounted) {
                                      setModalState(() {});
                                    }
                                  },
                            icon: _isFindingNearest
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: red,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                    color: red,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userPosition != null
                            ? 'Nearest branches appear first. Distances are approximate straight-line estimates.'
                            : (_locationStatus ??
                                'Choose the SupaClean location most convenient for you.'),
                        style: const TextStyle(fontSize: 12, color: grey),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: locations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final location = locations[index];
                            final isSelected =
                                location['name'] == selectedDepot;
                            final isNearest =
                                _userPosition != null && index == 0;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  Navigator.pop(sheetContext, location),
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFF0F0)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? red : border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_outlined,
                                        color: red,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            location['name'] ??
                                                'SupaClean Depot',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: dark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            location['address'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: grey,
                                            ),
                                          ),
                                          if (_userPosition != null) ...[
                                            const SizedBox(height: 7),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                if (isNearest)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 7,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFE8F5E9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Text(
                                                      'NEAREST TO YOU',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                            0xFF24733A),
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  _distanceLabel(location),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isSelected ? red : grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || depot == null) return;

    setState(() {
      if (forDropOff) {
        selectedDropOffDepot = depot['name'];
      } else {
        selectedCollectionDepot = depot['name'];
      }
    });
  }

  /// Asks for the customer's address, showing the fee for the area as they
  /// type. The fees on this screen follow the address that is saved.
  Future<void> _showAddressSheet() async {
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _AddressSheet(
        initialAddress: address,
        homePickup: _homePickup,
        homeDelivery: _homeDelivery,
        zoneFor: _zoneFor,
        defaultFee: _defaultHomeFee,
      ),
    );

    if (!mounted || saved == null) return;
    setState(() => address = saved);

    // Keep it on the customer's profile (My Addresses) straight away. If
    // saving fails they can still carry on with the order.
    AddressBook.addAndSelect(saved).catchError(
      (_) => const SavedAddresses(),
    );
  }

  /// The street address of a depot, for orders that use no home trip.
  String _depotAddress(String? name) => depotLocations.firstWhere(
        (depot) => depot['name'] == name,
        orElse: () => const <String, String>{},
      )['address'] ??
      '';

  void _continueOrder() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item.')),
      );
      return;
    }

    if (pickupOption == 'Drop off at depot' &&
        selectedDropOffDepot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a drop-off depot.')),
      );
      _showDepotPicker(forDropOff: true);
      return;
    }

    if (deliveryOption == 'Collect at depot' &&
        selectedCollectionDepot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a collection depot.')),
      );
      _showDepotPicker(forDropOff: false);
      return;
    }

    // Home pickup and delivery need an address in an area we serve.
    final needsAddress = _homePickup || _homeDelivery;
    if (needsAddress && AddressRules.problem(address) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your address for home pickup or delivery.'),
        ),
      );
      _showAddressSheet();
      return;
    }

    // Save this address for future orders. If saving fails, the customer can
    // still continue.
    if (needsAddress) {
      AddressBook.addAndSelect(address).catchError(
        (_) => const SavedAddresses(),
      );
    }

    final draft = OrderDraft(
      address: needsAddress
          ? address
          : _depotAddress(selectedDropOffDepot ?? selectedCollectionDepot),
      category: selectedCategory,
      lines: [
        for (final entry in selectedItems.entries)
          OrderLine(
            name: entry.value.name,
            unitPrice: entry.value.price,
            quantity: quantities[entry.key] ?? 1,
          ),
      ],
      pickupOption: pickupOption == 'Drop off at depot'
          ? '$pickupOption: ${selectedDropOffDepot ?? ''}'
          : pickupOption,
      deliveryOption: deliveryOption == 'Collect at depot'
          ? '$deliveryOption: ${selectedCollectionDepot ?? ''}'
          : deliveryOption,
      pickupFee: pickupCost,
      deliveryFee: deliveryCost,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseDateTimeScreen(
          orderSubtotal: subtotal,
          draft: draft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(title: 'Place New Order'),
      bottomNavigationBar: const FlowBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  const Text(
                    'Select Service',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      final isSelected = selectedCategory == service.name;

                      return InkWell(
                        onTap: () => _selectCategory(service),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? red : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? red : border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _serviceIcon(service.name),
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF4C5668),
                                size: 22,
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(
                                  _shortName(service.name),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : dark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _showAddItems,
                        child: const Text(
                          'Add items and specify weights',
                          style: TextStyle(fontSize: 9, color: grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selectedItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: const Text(
                        'No items selected. Tap Add items to get started.',
                        style: TextStyle(fontSize: 12, color: grey),
                      ),
                    )
                  else
                    ...selectedItems.entries.map((entry) {
                      final key = entry.key;
                      final item = entry.value;
                      final quantity = quantities[key] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.checkroom,
                                color: red,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: dark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.price == 0
                                        ? 'Price on assessment'
                                        : 'R${item.price.toStringAsFixed(2)}'
                                            '${_isPerKg(item) ? '/kg' : ' each'}'
                                            '${item.isEstimated ? ' (est.)' : ''}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _quantityButton(
                              icon: Icons.remove,
                              onTap: () => _changeQuantity(key, -1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7),
                              child: Text(
                                '$quantity${_isPerKg(item) ? ' kg' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: dark,
                                ),
                              ),
                            ),
                            _quantityButton(
                              icon: Icons.add,
                              onTap: () => _changeQuantity(key, 1),
                            ),
                          ],
                        ),
                      );
                    }),
                  Center(
                    child: TextButton.icon(
                      onPressed: _showAddItems,
                      icon: const Icon(Icons.add, size: 13, color: red),
                      label: const Text(
                        'Add More Items',
                        style: TextStyle(color: red, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Pickup & Delivery',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _optionTile(
                    icon: Icons.home_outlined,
                    title: 'Pickup Option',
                    value: pickupOption,
                    detail: pickupOption == 'Drop off at depot'
                        ? selectedDropOffDepot
                        : _addressDetail,
                    fee: pickupCost,
                    onTap: () => _chooseOption(
                      title: 'Choose pickup option',
                      options: ['At my address', 'Drop off at depot'],
                      current: pickupOption,
                      onSelected: (value) {
                        setState(() {
                          pickupOption = value;
                          if (value != 'Drop off at depot') {
                            selectedDropOffDepot = null;
                          }
                        });
                        if (value == 'Drop off at depot') {
                          _showDepotPicker(forDropOff: true);
                        } else {
                          _showAddressSheet();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _optionTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery Option',
                    value: deliveryOption,
                    detail: deliveryOption == 'Collect at depot'
                        ? selectedCollectionDepot
                        : _addressDetail,
                    fee: deliveryCost,
                    onTap: () => _chooseOption(
                      title: 'Choose delivery option',
                      options: ['Deliver to me', 'Collect at depot'],
                      current: deliveryOption,
                      onSelected: (value) {
                        setState(() {
                          deliveryOption = value;
                          if (value != 'Collect at depot') {
                            selectedCollectionDepot = null;
                          }
                        });
                        if (value == 'Collect at depot') {
                          _showDepotPicker(forDropOff: false);
                        } else {
                          _showAddressSheet();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _feeRow('Order subtotal', subtotal),
                        const SizedBox(height: 7),
                        _feeRow('Home pickup fee', pickupCost),
                        const SizedBox(height: 7),
                        _feeRow('Home delivery fee', deliveryCost),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 9),
                          child: Divider(height: 1, color: border),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dark,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total including fees',
                          style: TextStyle(fontSize: 10, color: grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'R${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _continueOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 27),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 23,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: red, size: 15),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String value,
    String? detail,
    required double fee,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: red, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: dark),
                  ),
                  if (detail != null && detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 10,
                    color: red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fee > 0)
                  Text(
                    '+ R${fee.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 9, color: grey),
                  )
                else
                  const Text(
                    'Free',
                    style: TextStyle(fontSize: 9, color: grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeRow(String label, double amount) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: grey),
        ),
        const Spacer(),
        Text(
          'R${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 11, color: dark),
        ),
      ],
    );
  }
}

/// Where the customer types their address for home pickup and delivery. It
/// shows the fee for the area the address is in while they type.
class _AddressSheet extends StatefulWidget {
  const _AddressSheet({
    required this.initialAddress,
    required this.homePickup,
    required this.homeDelivery,
    required this.zoneFor,
    required this.defaultFee,
  });

  final String initialAddress;
  final bool homePickup;
  final bool homeDelivery;
  final ({String id, String name, double fee})? Function(String) zoneFor;
  final double defaultFee;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  static const Color red = Color(0xFFEF3E46);
  static const Color background = Color(0xFFF7F8FA);
  static const Color dark = Color(0xFF202124);
  static const Color grey = Color(0xFF747982);
  static const Color border = Color(0xFFE6E8EC);

  late final TextEditingController _controller =
      TextEditingController(text: widget.initialAddress);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final typed = _controller.text.trim();
    final problem = AddressRules.problem(typed);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.pop(context, typed);
  }

  /// What the typed address will cost, in words.
  String _feeText(String typed) {
    if (typed.isEmpty) return 'Type your address to see the fee for your area.';

    final zone = widget.zoneFor(typed);
    final fee = zone?.fee ?? widget.defaultFee;
    final lines = [
      if (zone != null) 'Area: ${zone.name}',
      if (zone == null && AddressRules.isSupportedArea(typed))
        'Estimated fee until we confirm your area',
      if (zone == null && !AddressRules.isSupportedArea(typed))
        'We could not find your area yet. Include Bloemfontein, Botshabelo '
            'or Thaba Nchu.',
      if (zone != null || AddressRules.isSupportedArea(typed)) ...[
        if (widget.homePickup) 'Home pickup fee: R${fee.toStringAsFixed(2)}',
        if (widget.homeDelivery)
          'Home delivery fee: R${fee.toStringAsFixed(2)}',
      ],
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final typed = _controller.text.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'We collect from and deliver to this address. '
              'The fee depends on your area.',
              style: TextStyle(fontSize: 12, color: grey),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _error == null ? border : red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: red, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (_) => setState(() => _error = null),
                      style: const TextStyle(fontSize: 13, color: dark),
                      decoration: const InputDecoration(
                        hintText: 'Enter your street address, suburb, city',
                        hintStyle:
                            TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Example: 12 Example Street, Langenhoven Park, Bloemfontein. '
                'Include your house or stand number, street or section, '
                'suburb, and town.',
                style: TextStyle(fontSize: 12, color: grey, height: 1.4),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _feeText(typed),
                style: const TextStyle(fontSize: 12, color: dark, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Save address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
