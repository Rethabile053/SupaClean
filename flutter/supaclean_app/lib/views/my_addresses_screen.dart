import 'package:flutter/material.dart';
import '../models/address_rules.dart';
import '../services/address_book.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';

const _red = Color(0xFFE5393D);
const _line = Color(0xFFE8E9EC);

/// Profile > My Addresses: add addresses and choose which one new orders
/// use. Addresses entered on Place New Order are saved here too.
class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  SavedAddresses _book = AddressBook.load();

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<SavedAddresses> Function() action) async {
    try {
      final result = await action();
      if (mounted) setState(() => _book = result);
    } catch (_) {
      _snack('Could not save your addresses. Please try again.');
    }
  }

  Future<void> _add() async {
    final address = await showDialog<String>(
      context: context,
      builder: (context) => const _AddAddressDialog(),
    );
    if (address == null || address.isEmpty) return;
    await _run(() => AddressBook.addAndSelect(address));
  }

  @override
  Widget build(BuildContext context) {
    final addresses = _book.all;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: const AppHeader(title: 'My Addresses'),
      body: addresses.isEmpty
          ? const EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Add one here, or enter it when you book a pickup.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final address = addresses[index];
                final selected = address == _book.selected;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _run(() => AddressBook.select(address)),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? _red : _line,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? _red : const Color(0xFF9AA0AB),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (selected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Used for new orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete address',
                            icon: const Icon(Icons.delete_outline),
                            color: const Color(0xFF9AA0AB),
                            onPressed: () =>
                                _run(() => AddressBook.remove(address)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add new address',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for a new address and refuses one that can't be used for pickup or
/// delivery. Owns its text controller so it is disposed with the dialog.
class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog();

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final typed = _controller.text.trim();
    final problem = AddressRules.problem(typed);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.pop(context, typed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add address'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        minLines: 1,
        maxLines: 3,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: 'Street address, suburb, city',
          helperText: 'Include a house or stand number, street, suburb '
              'and town (Bloemfontein, Botshabelo or Thaba Nchu).',
          helperMaxLines: 3,
          errorText: _error,
          errorMaxLines: 4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
