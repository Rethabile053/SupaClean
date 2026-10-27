
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

import '../services/api_client.dart';
import '../services/proof_uploader.dart';
import '../widgets/app_header.dart';

const bankRed = Color(0xFFE53935);
const bankLine = Color(0xFFE0E0E0);
const bankMuted = Color(0xFF626976);

class BankTransferPayment extends StatefulWidget {
  const BankTransferPayment({
    super.key,
    required this.orderId,
    required this.amount,
    this.onProofSelected,
    this.onSubmit,
    this.showProofSection = true,
  });

  final String orderId;
  final double amount;
  final bool showProofSection;

  final ValueChanged<file_picker.PlatformFile>? onProofSelected;

  final Future<void> Function(ProofFile proof)? onSubmit;

  @override
  State<BankTransferPayment> createState() =>
      _BankTransferPaymentState();
}

class _BankTransferPaymentState extends State<BankTransferPayment> {
  file_picker.PlatformFile? selectedFile;
  bool submitting = false;

  // Replace these placeholders with SupaClean's real bank details.
  final Map<String, String> bankDetails = {
    'Account name': 'SupaClean (Your Registered Name)',
    'Bank name': 'Your Bank Name',
    'Account number': 'YOUR_ACCOUNT_NUMBER',
    'Branch code': 'YOUR_BRANCH_CODE',
    'Account type': 'Business Cheque',
  };

  String get reference => 'Order ID #${widget.orderId}';

  Future<void> copyText(String value) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> pickProof() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.size > 10 * 1024 * 1024) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file smaller than 10 MB.'),
        ),
      );
      return;
    }

    setState(() => selectedFile = file);
    widget.onProofSelected?.call(file);
  }

  Future<void> submitProof() async {
    final file = selectedFile;
    final bytes = file?.bytes;

    if (file == null || bytes == null || submitting) return;
    if (widget.onSubmit == null) return;

    setState(() => submitting = true);

    try {
      await widget.onSubmit!(
        ProofFile(name: file.name, bytes: bytes),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof submitted successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not submit proof. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  Widget bankField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: bankLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: bankMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy $label',
            onPressed: () => copyText(value),
            icon: const Icon(Icons.copy_outlined, color: bankRed),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const AppHeader(title: 'Bank Transfer / EFT'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: bankRed,
            size: 52,
          ),
          const SizedBox(height: 12),
          const Text(
            'Pay using Bank Transfer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount to pay: R${widget.amount.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: bankRed,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Company Banking Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          ...bankDetails.entries.map(
            (entry) => bankField(entry.key, entry.value),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bankLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Unique Payment Reference',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        reference,
                        style: const TextStyle(
                          color: bankRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => copyText(reference),
                      icon: const Icon(Icons.copy, color: bankRed),
                    ),
                  ],
                ),
                const Text(
                  'Use this exact reference when making your transfer.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'How to Pay',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Open your banking app.\n'
            '2. Transfer the exact amount to the account above.\n'
            '3. Enter your unique order reference.\n'
            '4. Complete the transfer and save your receipt.\n'
            '5. Return to SupaClean and select your receipt below.\n'
            '6. Wait for SupaClean to verify the payment.',
          ),
          if (widget.showProofSection) ...[
            const SizedBox(height: 22),
            const Text(
              'Proof of Payment',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: submitting ? null : pickProof,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose receipt (PDF or image)'),
            ),
            if (selectedFile != null) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: bankRed,
                ),
                title: Text(selectedFile!.name),
                subtitle: Text(
                  '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: submitting
                      ? null
                      : () => setState(() => selectedFile = null),
                ),
              ),
            ],
            if (widget.onSubmit != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: selectedFile == null || submitting
                      ? null
                      : submitProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bankRed,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Proof of Payment',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Your receipt can be selected here, but server submission '
                  'must be connected before it can be sent for verification.',
                  style: TextStyle(
                    color: bankMuted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
