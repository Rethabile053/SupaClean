import 'package:flutter/material.dart';

import '../models/laundry_order.dart';
import '../services/api_client.dart';
import '../services/order_api.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import 'track_order_screen.dart';

/// Opens Track Your Order for an order we only know the id of, such as the order
/// a notification is about. It fetches the order, then shows the tracking screen.
class TrackOrderLoader extends StatefulWidget {
  const TrackOrderLoader({super.key, required this.orderId, this.load});

  /// The server's id for the order (the orderId in a notification).
  final String orderId;

  /// Replaces the server call (used by tests).
  final Future<LaundryOrder> Function(String orderId)? load;

  @override
  State<TrackOrderLoader> createState() => _TrackOrderLoaderState();
}

class _TrackOrderLoaderState extends State<TrackOrderLoader> {
  late Future<LaundryOrder> _future = _fetch();

  Future<LaundryOrder> _fetch() => widget.load != null
      ? widget.load!(widget.orderId)
      : OrderApi().order(widget.orderId);

  void _retry() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LaundryOrder>(
      future: _future,
      builder: (context, snapshot) {
        final order = snapshot.data;
        if (order != null) {
          // The tracking screen has its own header, and keeps itself up to date.
          // A test loader is used for those updates too, and not the server.
          final test = widget.load;
          return TrackOrderScreen(
            order: order,
            load: test == null ? null : () => test(widget.orderId),
            refreshEvery: test == null ? const Duration(seconds: 30) : null,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: const AppHeader(title: 'Track Your Order'),
          body: snapshot.hasError
              ? ErrorState(
                  message: snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'We could not open this order. Please try again.',
                  onRetry: _retry,
                )
              : const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE53935)),
                ),
        );
      },
    );
  }
}
