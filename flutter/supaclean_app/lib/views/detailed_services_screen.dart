import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/sticky_cta_bar.dart';
import 'place_order_screen.dart';

/// Lists the items of one service as a checklist. The ticked items are
/// carried into Place Order.
class DetailedServicesScreen extends StatefulWidget {
  final String category;

  const DetailedServicesScreen({
    super.key,
    required this.category,
  });

  @override
  State<DetailedServicesScreen> createState() => _DetailedServicesScreenState();
}

class _DetailedServicesScreenState extends State<DetailedServicesScreen> {
  final ServiceViewModel viewModel = ServiceViewModel();

  /// Names of the ticked items.
  final Set<String> _selected = {};

  late final List<ServiceItem> _items =
      viewModel.getItemsForCategory(widget.category);

  bool get _hasEstimatedPrices =>
      widget.category == 'Ironing' || widget.category == 'Shoe Cleaning';

  bool get _isSpecialServices => widget.category == 'Other Special Services';

  void _toggle(ServiceItem item) {
    setState(() {
      if (!_selected.remove(item.name)) _selected.add(item.name);
    });
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderScreen(
          category: widget.category,
          initialItems: _items
              .where((item) => _selected.contains(item.name))
              .map((item) => item.name)
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;

    return Scaffold(
      appBar: const AppHeader(title: 'Detailed Services'),
      bottomNavigationBar: StickyCtaBar(
        summaryLabel: count == 0
            ? 'Tick what you need'
            : '$count ${count == 1 ? 'item' : 'items'} selected',
        buttonText: 'Place order',
        onPressed: count == 0 ? null : _continue,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s16,
            AppSpace.s8,
            AppSpace.s16,
            AppSpace.s24,
          ),
          children: [
            Text(widget.category, style: AppText.display),
            const SizedBox(height: AppSpace.s8),
            Text(
              _isSpecialServices
                  ? 'Specialist cleaning for carpets and leather garments.'
                  : 'Tick the items you want cleaned, then place your order.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.s24),
            if (_hasEstimatedPrices)
              const _Notice(
                icon: Icons.info_outline,
                tone: StatusTone.warning,
                text: 'These prices are estimates for the prototype and may '
                    'change. Please confirm the final price with SupaClean.',
              ),
            if (_isSpecialServices)
              const _Notice(
                icon: Icons.fact_check_outlined,
                tone: StatusTone.progress,
                text: 'Special items may require assessment before cleaning '
                    'can be accepted. SupaClean will confirm whether the item '
                    'can be cleaned and provide the applicable price.',
              ),
            if (_items.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(AppSpace.s24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 44,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: AppSpace.s12),
                    Text('No services available yet.', style: AppText.title),
                  ],
                ),
              )
            else
              for (final item in _items) ...[
                _ItemRow(
                  item: item,
                  selected: _selected.contains(item.name),
                  priceOnAssessment: _isSpecialServices,
                  onTap: () => _toggle(item),
                ),
                const SizedBox(height: AppSpace.s12),
              ],
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ServiceItem item;
  final bool selected;
  final bool priceOnAssessment;
  final VoidCallback onTap;

  const _ItemRow({
    required this.item,
    required this.selected,
    required this.priceOnAssessment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = priceOnAssessment
        ? 'Price after assessment'
        : 'R${item.price.toStringAsFixed(2)}'
            '${item.isEstimated ? ' (estimated)' : ''}';

    return AppCard(
      onTap: onTap,
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderColor: selected ? AppColors.primary : AppColors.border,
      borderWidth: selected ? 1.5 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The whole card toggles, so the box itself is not interactive.
          IgnorePointer(
            child: Checkbox(
              value: selected,
              onChanged: (_) {},
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.textGrey, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppText.bodyStrong),
                  const SizedBox(height: AppSpace.s4),
                  Text(item.description, style: AppText.body),
                  const SizedBox(height: AppSpace.s8),
                  Text(price, style: AppText.figures(AppText.bodyStrong)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final StatusTone tone;
  final String text;

  const _Notice({required this.icon, required this.tone, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s16),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tone.foreground),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Text(
                text,
                style: AppText.body.copyWith(color: tone.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
