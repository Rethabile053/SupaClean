import 'package:flutter/material.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_header.dart';
import 'date_time_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String category;

  const PlaceOrderScreen({
    super.key,
    required this.category,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final ServiceViewModel viewModel = ServiceViewModel();

  static const Color red = Color(0xFFEF3E46);
  static const Color background = Color(0xFFF7F8FA);
  static const Color dark = Color(0xFF202124);
  static const Color grey = Color(0xFF747982);
  static const Color border = Color(0xFFE6E8EC);

  // Change these amounts here if SupaClean updates its fees.
  static const double pickupFee = 50.00;
  static const double deliveryFee = 50.00;

  late String selectedCategory;

  final Map<String, ServiceItem> selectedItems = {};
  final Map<String, int> quantities = {};

  String pickupOption = 'At my address';
  String deliveryOption = 'Deliver to me';

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

  double get pickupCost => pickupOption == 'At my address' ? pickupFee : 0;

  double get deliveryCost =>
      deliveryOption == 'Deliver to me' ? deliveryFee : 0;

  double get total => subtotal + pickupCost + deliveryCost;

  @override
  void initState() {
    super.initState();

    selectedCategory = services.any(
      (service) => service.name == widget.category,
    )
        ? widget.category
        : services.first.name;

    _addInitialItem();
  }

  void _addInitialItem() {
    final items = currentCategory.items;

    if (items.isNotEmpty) {
      final item = items.first;
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
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
                          item.price == 0
                              ? 'Price confirmed after assessment'
                              : 'R${item.price.toStringAsFixed(2)}'
                                  '${_isPerKg(item) ? '/kg' : ' each'}'
                                  '${item.isEstimated ? ' (estimated)' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: grey,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _addItem(item),
                          icon: const Icon(
                            Icons.add_circle,
                            color: red,
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
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
                      onSelected(option);
                      Navigator.pop(sheetContext);
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

  // Navigate to the Choose Date & Time screen.
  void _continueOrder() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseDateTimeScreen(
          orderSubtotal: subtotal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(title: 'Place New Order'),
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

                  // Service selection grid
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
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

                  // Items heading
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
                          style: TextStyle(
                            fontSize: 9,
                            color: grey,
                          ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: grey,
                        ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
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
                      icon: const Icon(
                        Icons.add,
                        size: 13,
                        color: red,
                      ),
                      label: const Text(
                        'Add More Items',
                        style: TextStyle(
                          color: red,
                          fontSize: 11,
                        ),
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
                    fee: pickupCost,
                    onTap: () => _chooseOption(
                      title: 'Choose pickup option',
                      options: [
                        'At my address',
                        'Drop off at depot',
                      ],
                      current: pickupOption,
                      onSelected: (value) {
                        setState(() => pickupOption = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  _optionTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery Option',
                    value: deliveryOption,
                    fee: deliveryCost,
                    onTap: () => _chooseOption(
                      title: 'Choose delivery option',
                      options: [
                        'Deliver to me',
                        'Collect at depot',
                      ],
                      current: deliveryOption,
                      onSelected: (value) {
                        setState(() => deliveryOption = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Clear fee breakdown
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

            // Fixed bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: border),
                ),
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
                          style: TextStyle(
                            fontSize: 10,
                            color: grey,
                          ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 27,
                        ),
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
        child: Icon(
          icon,
          color: red,
          size: 15,
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String value,
    required double fee,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: dark,
                ),
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
                    style: const TextStyle(
                      fontSize: 9,
                      color: grey,
                    ),
                  )
                else
                  const Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 9,
                      color: grey,
                    ),
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
          style: const TextStyle(
            fontSize: 11,
            color: grey,
          ),
        ),
        const Spacer(),
        Text(
          'R${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 11,
            color: dark,
          ),
        ),
      ],
    );
  }
}