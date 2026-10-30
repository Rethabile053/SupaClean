import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/app_notification.dart';
import '../models/app_search.dart';
import '../models/laundry_order.dart';
import '../services/order_api.dart';
import '../services/service_catalogue.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import 'detailed_services_screen.dart';
import 'main_shell.dart';
import 'my_addresses_screen.dart';
import 'notification_center_screen.dart';
import 'services_screen.dart';
import 'terms_screen.dart';
import 'track_order_loader.dart';
import 'track_order_screen.dart';

/// Search across the whole app: pages, services, the customer's own orders and
/// their notifications. Opened from the magnifier next to the notification bell.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.loadOrders,
    this.loadNotifications,
    this.initialQuery = '',
  });

  /// Replace the server calls (used by tests).
  final Future<List<LaundryOrder>> Function()? loadOrders;
  final Future<List<AppNotification>> Function()? loadNotifications;

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with ServiceCatalogueWatcher {
  static const _grey = Color(0xFF747982);
  static const _border = Color(0xFFE6E8EC);

  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  final ServiceViewModel _services = ServiceViewModel();

  List<LaundryOrder> _orders = const [];
  List<AppNotification> _notifications = const [];
  bool _loading = true;
  bool _partial = false;

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The customer's orders and notifications come from the server. If one
  /// cannot be fetched the rest still works, and a note says so.
  Future<void> _loadMine() async {
    var failed = false;

    Future<List<T>> safe<T>(Future<List<T>> Function() call) async {
      try {
        return await call();
      } catch (_) {
        failed = true;
        return <T>[];
      }
    }

    final orders = await safe(() => widget.loadOrders != null
        ? widget.loadOrders!()
        : OrderApi().myOrders());
    final notifications = await safe(() => widget.loadNotifications != null
        ? widget.loadNotifications!()
        : OrderApi().notifications());

    if (!mounted) return;
    setState(() {
      _orders = orders;
      _notifications = notifications;
      _partial = failed;
      _loading = false;
    });
  }

  void _open(SearchResult result) {
    final source = result.source;

    switch (result.kind) {
      case SearchKind.page:
        _openPage(source as AppPage);
      case SearchKind.service:
        _go(DetailedServicesScreen(category: (source as ServiceCategory).name));
      case SearchKind.order:
        _go(TrackOrderScreen(order: source as LaundryOrder));
      case SearchKind.notification:
        final n = source as AppNotification;
        _go(n.orderId.isEmpty
            ? const NotificationCenterScreen()
            : TrackOrderLoader(orderId: n.orderId));
    }
  }

  void _openPage(AppPage page) {
    switch (page) {
      case AppPage.home:
        MainShell.switchTab(context, MainShell.homeTab);
      case AppPage.myOrders:
        MainShell.switchTab(context, MainShell.ordersTab);
      case AppPage.schedule:
        MainShell.switchTab(context, MainShell.scheduleTab);
      case AppPage.profile:
        MainShell.switchTab(context, MainShell.profileTab);
      case AppPage.services:
        _go(const ServicesScreen());
      case AppPage.addresses:
        _go(const MyAddressesScreen());
      case AppPage.notifications:
        _go(const NotificationCenterScreen());
      case AppPage.terms:
        _go(const TermsScreen());
    }
  }

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final results = searchApp(
      query,
      services: _services.services,
      orders: _orders,
      notifications: _notifications,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: const AppHeader(title: 'Search', showSearch: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Search services, orders, notifications…',
                          hintStyle:
                              TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close, size: 18),
                        color: _grey,
                        onPressed: () => setState(_controller.clear),
                      ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                ),
              ),
            if (_partial && !_loading)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Your orders or notifications could not be loaded, so they are not in these results.',
                  style: TextStyle(fontSize: 12, color: _grey),
                ),
              ),
            Expanded(child: _body(query, results)),
          ],
        ),
      ),
    );
  }

  Widget _body(String query, List<SearchResult> results) {
    if (query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search SupaClean',
        message:
            'Find a service, one of your orders, a notification, or a page like Terms and Conditions.',
      );
    }

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nothing found',
        message: _loading
            ? 'Still looking through your orders and notifications…'
            : 'No results for "${query.trim()}". Try another word.',
      );
    }

    final children = <Widget>[];
    for (final kind in SearchKind.values) {
      final group = results.where((r) => r.kind == kind).toList();
      if (group.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(
          kind.heading,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _grey,
          ),
        ),
      ));
      for (final result in group) {
        children.add(_ResultTile(result: result, onTap: () => _open(result)));
      }
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: children,
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6E8EC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(result.icon,
                      color: const Color(0xFFE5393D), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        result.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF747982),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
