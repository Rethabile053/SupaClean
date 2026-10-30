import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_header.dart';

const _red = Color(0xFFE5393D);
const _line = Color(0xFFE8E9EC);

/// Profile > Contact Us: every depot with its address and phone number.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  /// The depots, as in the pickup points kept on the server.
  static const depots = <({String name, String address, String phone})>[
    (
      name: 'Mimosa Mall',
      address:
          'Lower Retail Level, 131 Kellner Street, Brandwag, Bloemfontein, 9301',
      phone: '051 430 4241',
    ),
    (
      name: 'Fleurdal Mall',
      address:
          'Kiosk 2C, Entrance 2, Fleurdal Mall, Vereeniging Drive, Fleurdal, Bloemfontein, 9301',
      phone: '081 456 2999',
    ),
    (
      name: 'Preller Square',
      address:
          'Suite 19, First Floor, Preller Square Shopping Centre, Graaf Reinet Street, Dan Pienaar, Bloemfontein, 9301',
      phone: '081 503 9427',
    ),
    (
      name: 'Bloem Plaza',
      address:
          'Corner Charlotte Maxeke and East Burger Streets, Bloemfontein, 9300',
      phone: '083 417 3561',
    ),
    (
      name: 'Main Factory - Hamilton',
      address: '15 Piet Human Street, Hamilton, Bloemfontein, 9301',
      phone: '051 430 4241',
    ),
    (
      name: 'Botshabelo',
      address: 'Centre Strand Street, Botshabelo, 9781',
      phone: '081 338 5843',
    ),
    (
      name: 'Thaba Nchu',
      address: 'Main Street, Cornerstone Building, Thaba Nchu, 9780',
      phone: '081 338 5873',
    ),
  ];

  Future<void> _copy(BuildContext context, String name, String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$name number copied: $phone')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: const AppHeader(title: 'Contact Us'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: depots.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Call or visit any of our depots.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF626976)),
                ),
              );
            }

            final depot = depots[index - 1];
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
                  const Icon(Icons.storefront_outlined, color: _red, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depot.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          depot.address,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF626976),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 18, color: _red),
                            const SizedBox(width: 6),
                            Text(
                              depot.phone,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy ${depot.name} number',
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    onPressed: () => _copy(context, depot.name, depot.phone),
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
