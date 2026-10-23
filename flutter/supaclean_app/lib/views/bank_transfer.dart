
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../services/api_client.dart';
import '../services/proof_uploader.dart';

const payRed = Color(0xFFE53935);
const payLine = Color(0xFFE0E0E0);
const payMuted = Color(0xFF626976);

class BankTransferPayment extends StatefulWidget {
  const BankTransferPayment({
    super.key,
    required this.orderId,
    required this.amount,
    this.onProofSelected,
    this.onSubmit,
  });

  final String orderId;
  final double amount;
  final ValueChanged<file_picker.PlatformFile>? onProofSelected;

  /// Sends the chosen proof to SupaClean. When set, a Submit button appears;
  /// throw [ApiException] to show an error and let the customer retry.
  final Future<void> Function(ProofFile proof)? onSubmit;

  @override
  State<BankTransferPayment> createState() =>
      _BankTransferPaymentState();
}

class _BankTransferPaymentState
    extends State<BankTransferPayment> {
  file_picker.PlatformFile? selectedFile;
  bool submitting = false;

  // Replace these placeholders with your actual business details.
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

    setState(() => submitting = true);
    try {
      await widget.onSubmit!(ProofFile(name: file.name, bytes: bytes));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not send your proof. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
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
        border: Border.all(color: payLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      color: payMuted,
                      fontSize: 12,
                    )),
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
            icon: const Icon(Icons.copy_outlined, color: payRed),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Bank Transfer / EFT',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Amount to pay: R${widget.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: payRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Company banking details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
            border: Border.all(color: payLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your unique payment reference',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      reference,
                      style: const TextStyle(
                        color: payRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => copyText(reference),
                    icon: const Icon(Icons.copy, color: payRed),
                  ),
                ],
              ),
              const Text(
                'Use this exact reference when making the transfer. '
                'Do not substitute your name or another reference.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'How to pay',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '1. Open your banking app or online banking outside SupaClean.\n'
          '2. Transfer the exact amount to the account shown above.\n'
          '3. Enter the unique order reference exactly as displayed.\n'
          '4. Complete the transfer and save your bank receipt.\n'
          '5. Return to SupaClean and upload the receipt below.\n'
          '6. Wait for SupaClean to verify the payment.',
        ),
        const SizedBox(height: 20),
        const Text(
          'Proof of payment',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: pickProof,
          icon: const Icon(Icons.upload_file),
          label: const Text('Choose receipt (PDF or image)'),
        ),
        if (selectedFile != null) ...[
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.insert_drive_file, color: payRed),
            title: Text(selectedFile!.name),
            subtitle: Text(
              '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => selectedFile = null),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (widget.onSubmit != null) ...[
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: selectedFile == null || submitting ? null : submitProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: payRed,
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
                      'Submit proof of payment',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SupaClean checks your payment and confirms your order. '
            "We'll notify you.",
            style: TextStyle(color: payMuted, fontSize: 12),
          ),
        ] else
          const Text(
            'Selecting a file does not submit it to the server. '
            'Upload it securely and wait for verification before '
            'marking the order as paid.',
            style: TextStyle(color: payMuted, fontSize: 12),
          ),
      ],
    );
  }
}
