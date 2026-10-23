import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/proof_uploader.dart';
import '../widgets/app_header.dart';
import 'bank_transfer.dart';
import 'main_shell.dart';

const _red = Color(0xFFEB3838);
const _ink = Color(0xFF242424);
const _muted = Color(0xFF777777);
const _canvas = Color(0xFFF8F9FB);
const _line = Color(0xFFE8E9EC);
const _maxBytes = 5 * 1024 * 1024;

/// What the customer chose to send: a PDF, or the bank's confirmation pasted
/// as text. Exactly one of the two is set.
class ProofSubmission {
  const ProofSubmission.file(ProofFile this.file) : text = null;
  const ProofSubmission.text(String this.text) : file = null;

  final ProofFile? file;
  final String? text;
}

/// Asks the customer for their proof of payment after choosing bank transfer.
/// [onSubmit] sends it; throw [ApiException] to show a message and let them
/// try again.
class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({
    super.key,
    required this.orderNumber,
    required this.orderSummary,
    required this.amount,
    required this.onSubmit,
  });

  final String orderNumber;
  final String orderSummary;
  final double amount;
  final Future<void> Function(ProofSubmission proof) onSubmit;

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  final _text = TextEditingController();
  bool _pasteMode = false;
  file_picker.PlatformFile? _file;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ready =>
      _pasteMode ? _text.text.trim().length >= 10 : _file?.bytes != null;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPdf() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > _maxBytes) {
      _snack('Please choose a file smaller than 5 MB.');
      return;
    }
    setState(() => _file = file);
  }

  void _showBankDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Bank details')),
          body: BankTransferPayment(
            orderId: widget.orderNumber,
            amount: widget.amount,
            showProofSection: false,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_ready || _submitting) return;

    final proof = _pasteMode
        ? ProofSubmission.text(_text.text.trim())
        : ProofSubmission.file(
            ProofFile(name: _file!.name, bytes: _file!.bytes!),
          );

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(proof);
    } catch (error) {
      if (!mounted) return;
      _snack(
        error is ApiException
            ? error.message
            : 'Could not send your proof. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: const AppHeader(title: 'Upload Proof of Payment'),
      bottomNavigationBar:
          const FlowBottomNav(selected: MainShell.scheduleTab),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                children: [
                  _orderCard(),
                  const SizedBox(height: 22),
                  const Text(
                    'How would you like to add proof?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _modeSwitch(),
                  const SizedBox(height: 14),
                  _pasteMode ? _pasteBox() : _uploadBox(),
                  const SizedBox(height: 14),
                  _hint(),
                  TextButton.icon(
                    onPressed: _showBankDetails,
                    icon: const Icon(Icons.account_balance_outlined, size: 18),
                    label: const Text('View bank details and reference'),
                    style: TextButton.styleFrom(foregroundColor: _red),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _line)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _ready && !_submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Submit Proof of Payment',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.orderNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.orderSummary,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Payment due',
                style: TextStyle(fontSize: 12, color: _red),
              ),
              const SizedBox(height: 4),
              Text(
                'R${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeSwitch() {
    Widget option(String label, IconData icon, bool paste) {
      final selected = _pasteMode == paste;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _pasteMode = paste),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFEAEA) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: _red),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _ink,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: _box(),
      child: Row(
        children: [
          option('Upload PDF', Icons.picture_as_pdf_outlined, false),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('or', style: TextStyle(color: _muted, fontSize: 13)),
          ),
          option('Enter / paste text', Icons.text_fields, true),
        ],
      ),
    );
  }

  Widget _uploadBox() {
    final file = _file;
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickPdf,
        child: Container(
          height: 190,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFEAEA),
                child: Icon(
                  file == null
                      ? Icons.cloud_upload_outlined
                      : Icons.check_circle_outline,
                  color: _red,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                file == null ? 'Choose your proof of payment' : file.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                file == null
                    ? 'PDF only · Maximum file size 5 MB'
                    : '${(file.size / 1024).toStringAsFixed(1)} KB · '
                        'tap to change',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pasteBox() {
    return Container(
      decoration: _box(),
      child: TextField(
        controller: _text,
        minLines: 7,
        maxLines: 7,
        maxLength: 500,
        decoration: const InputDecoration(
          hintText: 'Paste your bank confirmation here',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _hint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _red, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Make sure the amount, payment date and bank reference are '
              'clearly visible. You can also paste your bank confirmation '
              'as text.',
              style: TextStyle(fontSize: 12.5, color: _ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(14),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
