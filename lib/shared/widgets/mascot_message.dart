import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'floating_decoration.dart';

/// Empty / error state with a BeBo mascot pose instead of a bare line of text.
class MascotMessage extends StatelessWidget {
  const MascotMessage({
    super.key,
    required this.title,
    this.message,
    this.mascot = AppAssets.mascotEmpty,
    this.actionLabel,
    this.onAction,
  });

  /// Offline / failed load.
  const MascotMessage.error({
    super.key,
    this.title = 'النت فصل شوية',
    this.message = 'اتأكدي من الإنترنت وجربي تاني.',
    this.actionLabel = 'جربي تاني',
    this.onAction,
  }) : mascot = AppAssets.mascotOffline;

  final String title;
  final String? message;
  final String mascot;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingDecoration(
              amplitude: 8,
              child: Image.asset(
                mascot,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
