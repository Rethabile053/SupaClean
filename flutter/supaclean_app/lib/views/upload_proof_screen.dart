import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../services/api_client.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/pressable.dart';
import '../widgets/status_badge.dart';
import '../widgets/sticky_cta_bar.dart';

/// Step after Pay for bank transfers: the customer uploads a photo or
/// screenshot of their payment. Pops with `true` once [onSubmit] succeeds.
class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({
    super.key,
    required this.amountDue,
    required this.onSubmit,
    this.pickImage,
  });

  final double amountDue;

  /// Sends the proof to the server. Throw [ApiException] with a friendly
  /// message to show an error and let the user try again.
  final Future<void> Function(XFile proof) onSubmit;

  /// Replaces the camera / gallery picker (used by tests).
  final Future<XFile?> Function(ImageSource source)? pickImage;

  static const int maxBytes = 5 * 1024 * 1024;

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  XFile? _proof;
  Uint8List? _preview;
  bool _submitting = false;
  String? _error;

  Future<XFile?> _pick(ImageSource source) =>
      widget.pickImage?.call(source) ??
      ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );

  Future<void> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await _pick(source);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > UploadProofScreen.maxBytes) {
        setState(() => _error = 'That file is too big. Please use one under 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _proof = file;
        _preview = bytes;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open your photos. Please try again.');
      }
    }
  }

  Future<void> _submit() async {
    final proof = _proof;
    if (proof == null || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(proof);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Upload proof of payment'),
      bottomNavigationBar: StickyCtaBar(
        summaryLabel: 'Amount to pay',
        summaryValue: 'R${widget.amountDue.toStringAsFixed(2)}',
        buttonText: 'Submit',
        isLoading: _submitting,
        onPressed: _proof == null ? null : _submit,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          AppSpace.s24,
        ),
        children: [
          const Text(
            'Pay by bank transfer, then upload a photo or screenshot of your '
            'payment. We check it and confirm your order.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.s24),
          if (PaymentConfig.hasBankDetails) ...[
            const _BankDetailsCard(),
            const SizedBox(height: AppSpace.s24),
          ],
          _UploadZone(
            preview: _preview,
            onTap: _submitting ? null : _choose,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.s12),
            Container(
              padding: const EdgeInsets.all(AppSpace.s12),
              decoration: BoxDecoration(
                color: StatusTone.danger.background,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: StatusTone.danger.foreground,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppText.body.copyWith(
                        color: StatusTone.danger.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.s16),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.textGrey),
              SizedBox(width: AppSpace.s8),
              Expanded(
                child: Text(
                  'Your proof is only seen by SupaClean.',
                  style: AppText.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  final Uint8List? preview;
  final VoidCallback? onTap;

  const _UploadZone({required this.preview, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = preview != null;

    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: hasImage ? AppColors.surface : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: hasImage ? AppColors.border : AppColors.primary,
            width: hasImage ? 1 : 1.5,
          ),
        ),
        child: hasImage
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    child: Image.memory(
                      preview!,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(AppSpace.s12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
                        SizedBox(width: AppSpace.s8),
                        Text('Change photo', style: AppText.bodyStrong),
                      ],
                    ),
                  ),
                ],
              )
            : const Padding(
                padding: EdgeInsets.all(AppSpace.s24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: AppSpace.s12),
                    Text('Tap to add your proof', style: AppText.title),
                    SizedBox(height: AppSpace.s4),
                    Text(
                      'A clear photo or screenshot (JPG or PNG, up to 5 MB)',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// SupaClean's bank details with one-tap copy. Only shown once they are
/// filled in in PaymentConfig.
class _BankDetailsCard extends StatelessWidget {
  const _BankDetailsCard();

  @override
  Widget build(BuildContext context) {
    final rows = {
      'Bank': PaymentConfig.bankName,
      'Account holder': PaymentConfig.accountHolder,
      'Account number': PaymentConfig.accountNumber,
      'Branch code': PaymentConfig.branchCode,
    }..removeWhere((_, value) => value.isEmpty);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pay to', style: AppText.title),
          const SizedBox(height: AppSpace.s8),
          for (final entry in rows.entries)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: AppText.caption),
                      Text(
                        entry.value,
                        style: AppText.figures(AppText.bodyStrong),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy ${entry.key.toLowerCase()}',
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${entry.key} copied')),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
