import 'package:flutter/material.dart';
import '../theme/spacing.dart';

/// A filled tonal pill for a trip's status (Draft / Planned). Reads at a glance
/// and stays colorblind-safe by carrying its label, not just a colored dot.
/// Shared by the trips list and the trip-detail header.
class StatusPill extends StatelessWidget {
  final String status;

  /// Optional trailing widget (e.g. a dropdown arrow when the pill doubles as a
  /// status picker trigger). Tinted to match the label.
  final Widget? trailing;

  const StatusPill({super.key, required this.status, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlanned = status == 'planned';
    final label = status.isEmpty
        ? 'Draft'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    // Planned reads as a positive, completed state (green); anything else is a
    // neutral surface tone so it doesn't compete for attention.
    final Color bg = isPlanned
        ? Colors.green.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    final Color fg =
        isPlanned ? Colors.green.shade800 : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlanned ? Icons.check_circle : Icons.edit_note,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null)
            IconTheme.merge(
              data: IconThemeData(color: fg, size: 18),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
