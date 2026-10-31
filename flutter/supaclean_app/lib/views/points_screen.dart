import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/points.dart';
import '../services/points_store.dart';
import '../widgets/app_header.dart';

/// The customer's points: the balance, what it is worth, how points work and
/// every time they were earned or used.
class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key, this.store});

  /// Defaults to the shared store; tests pass their own.
  final PointsStore? store;

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  PointsStore get _store => widget.store ?? PointsStore.instance;

  @override
  void initState() {
    super.initState();
    _store.refresh();
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const AppHeader(title: 'My Points'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final summary = _store.summary;
            if (summary == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Your points will show here once you are connected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _balanceCard(summary),
                const SizedBox(height: 20),
                _howItWorks(summary),
                const SizedBox(height: 22),
                const Text(
                  'History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (summary.history.isEmpty)
                  const Text(
                    'No points yet. You earn them when an order is delivered.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  )
                else
                  for (final entry in summary.history) _entry(entry),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _balanceCard(PointsSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF43B40), Color(0xFFB9232B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR BALANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.balance} points',
            key: const Key('points-balance'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Worth R${summary.balanceValue.toStringAsFixed(0)} off your next order',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks(PointsSummary summary) {
    final maxPercent = (summary.maxShareOfItems * 100).round();
    final lines = [
      'Earn 1 point for every R${summary.randSpentPerPoint.toStringAsFixed(0)} '
          'you pay, once your order is delivered.',
      '${summary.pointsPerRand} points are worth R1 off.',
      'Points can cover up to $maxPercent% of your laundry price.',
      'If an order is cancelled, the points you used come back.',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How points work',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(line, style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _entry(PointsEntry entry) {
    final gained = entry.points > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _date(entry.time),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${gained ? '+' : ''}${entry.points}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: gained ? const Color(0xFF1E9E5A) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
