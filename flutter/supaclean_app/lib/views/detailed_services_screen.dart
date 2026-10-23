
import 'package:flutter/material.dart';
import 'package:supaclean/views/main_shell.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_header.dart';
import 'place_order_screen.dart';

/// Lists the items of one service as a checklist.
/// The selected items are carried into Place Order.
class DetailedServicesScreen extends StatefulWidget {
  final String category;

  const DetailedServicesScreen({
    super.key,
    required this.category,
  });

  @override
  State<DetailedServicesScreen> createState() =>
      _DetailedServicesScreenState();
}

class _DetailedServicesScreenState
    extends State<DetailedServicesScreen> {
  final ServiceViewModel viewModel = ServiceViewModel();

  /// Names of the selected items.
  final Set<String> _selected = {};

  static const Color primaryRed = Color(0xFFEF3E46);
  static const Color darkBlue = Color(0xFF12304A);
  static const Color background = Color(0xFFF5F8FC);

  String get category => widget.category;

  bool get hasEstimatedPrices =>
      category == 'Ironing' || category == 'Shoe Cleaning';

  bool get isSpecialServices =>
      category == 'Other Special Services';

  IconData getServiceIcon(String name) {
    switch (name) {
      case 'Wash & Fold':
        return Icons.local_laundry_service;
      case 'Dry Cleaning':
        return Icons.checkroom;
      case 'Ironing':
        return Icons.dry_cleaning;
      case 'Bedding & Linen':
        return Icons.bed;
      case 'Shoe Cleaning':
        return Icons.shopping_bag;
      case 'Other Special Services':
        return Icons.auto_awesome;
      case 'Carpet Cleaning':
        return Icons.grid_view;
      case 'Leather Garments':
        return Icons.checkroom;
      default:
        return Icons.cleaning_services;
    }
  }

  void _toggle(ServiceItem item) {
    setState(() {
      if (!_selected.remove(item.name)) {
        _selected.add(item.name);
      }
    });
  }

  void _placeOrder(List<ServiceItem> items) {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tick at least one item.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderScreen(
          category: category,
          initialItems: [
            for (final item in items)
              if (_selected.contains(item.name)) item.name,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = viewModel.getItemsForCategory(category);

    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(title: 'Detailed Services'),
      bottomNavigationBar: const FlowBottomNav(),

      // Rounded Place Order button matching the Continue button.
      floatingActionButton: SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: () => _placeOrder(items),
          icon: const Icon(
            Icons.shopping_bag_outlined,
            size: 18,
          ),
          label: Text(
            _selected.isEmpty
                ? 'Place Order'
                : 'Place Order (${_selected.length})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 27,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSpecialServices
                    ? 'Specialist cleaning for carpets and leather garments.'
                    : 'Tick the items you want, then press Place Order.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              if (hasEstimatedPrices) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'These prices are estimates for the prototype '
                          'and may change. Please confirm the final price '
                          'with SupaClean.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (isSpecialServices) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade100,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        color: darkBlue,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Special items may require assessment before '
                          'cleaning can be accepted. SupaClean will confirm '
                          'whether the item can be cleaned and provide '
                          'the applicable price.',
                          style: TextStyle(
                            fontSize: 13,
                            color: darkBlue,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: Colors.black38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No services available yet.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...items.map((item) {
                  final iconName =
                      isSpecialServices ? item.name : category;
                  final selected = _selected.contains(item.name);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggle(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? primaryRed
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: primaryRed.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              getServiceIcon(iconName),
                              color: primaryRed,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (isSpecialServices)
                                  const Text(
                                    'Price confirmed after assessment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryRed,
                                    ),
                                  )
                                else
                                  Text(
                                    'R${item.price.toStringAsFixed(2)}'
                                    '${item.isEstimated ? ' (estimated)' : ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: primaryRed,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IgnorePointer(
                            child: Checkbox(
                              value: selected,
                              onChanged: (_) {},
                              activeColor: primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
