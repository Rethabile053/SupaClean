import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

const _red = Color(0xFFE5393D);
const _line = Color(0xFFE8E9EC);

/// Profile > Terms and Conditions.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const terms = <({IconData icon, String title, String text})>[
    (
      icon: Icons.savings_outlined,
      title: 'Payment in advance',
      text: 'Pay in advance and get a 15% discount.',
    ),
    (
      icon: Icons.warning_amber_outlined,
      title: 'At your own risk',
      text: 'The following are at the customer\'s own risk: caps, white '
          'clothing, and clothing with beads and sequins.',
    ),
    (
      icon: Icons.dry_cleaning_outlined,
      title: 'Dry cleaning',
      text: 'Dry cleaning is done the same day, as long as there are no '
          'difficult stains and the clothes are brought in early.',
    ),
    (
      icon: Icons.local_laundry_service_outlined,
      title: 'Laundry',
      text: 'Laundry takes two days.',
    ),
    (
      icon: Icons.verified_outlined,
      title: 'Shoe repairs',
      text: 'Shoe repairs come with a 3 month guarantee.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: const AppHeader(title: 'Terms and Conditions'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: terms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final term = terms[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(term.icon, color: _red, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          term.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          term.text,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF626976),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
