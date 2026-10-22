import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import 'primary_button.dart';

/// Bottom bar pinned in the thumb zone: a running summary on the left and
/// the main action on the right. Use as a Scaffold.bottomNavigationBar.
class StickyCtaBar extends StatelessWidget {
  const StickyCtaBar({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.summaryLabel,
    this.summaryValue,
    this.isLoading = false,
  });

  /// Small caption, e.g. "3 items".
  final String? summaryLabel;

  /// Bold figure, e.g. "R 245.00".
  final String? summaryValue;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasSummary = summaryLabel != null || summaryValue != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s16,
            AppSpace.s12,
            AppSpace.s16,
            AppSpace.s12,
          ),
          child: Row(
            children: [
              if (hasSummary)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (summaryLabel != null)
                        Text(
                          summaryLabel!,
                          style: AppText.figures(AppText.caption),
                        ),
                      if (summaryValue != null)
                        Text(
                          summaryValue!,
                          style: AppText.figures(AppText.title),
                        ),
                    ],
                  ),
                ),
              if (hasSummary) const SizedBox(width: AppSpace.s16),
              Expanded(
                flex: hasSummary ? 1 : 2,
                child: PrimaryButton(
                  text: buttonText,
                  onPressed: onPressed,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
