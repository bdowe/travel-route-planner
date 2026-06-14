import 'package:flutter/material.dart';
import '../theme/spacing.dart';

/// A centered icon + title + message, with optional actions. One implementation
/// for every "nothing here yet", error, or "no results" state so they read the
/// same across the app instead of some being styled and others plain text.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  /// Optional buttons (e.g. a Retry or a CTA) rendered below the message.
  final List<Widget> actions;

  /// Tints the icon. Defaults to a muted primary.
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
