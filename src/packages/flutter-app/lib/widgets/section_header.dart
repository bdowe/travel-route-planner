import 'package:flutter/material.dart';

/// A section title with an optional trailing action (e.g. "Itinerary" + "Add
/// place"). Gives related groups a consistent header so the eye reads them as
/// sections rather than loose rows.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
