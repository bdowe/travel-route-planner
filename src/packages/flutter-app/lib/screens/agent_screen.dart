import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/chat_panel.dart';
import '../providers/plan_provider.dart';
import '../providers/route_provider.dart';
import 'route_optimizer_screen.dart';
import 'trip_detail_screen.dart';

class AgentScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  /// When set (with [initialMessage]), reopens an existing trip for refinement:
  /// the conversation is bound to this chat group so new itineraries append as
  /// versions of that trip rather than creating a duplicate.
  final String? chatId;

  const AgentScreen({super.key, this.initialMessage, this.chatId});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(planProvider.notifier);
        if (widget.chatId != null) {
          notifier.beginRefinement(chatId: widget.chatId!, seedMessage: widget.initialMessage!);
        } else {
          notifier.sendMessage(widget.initialMessage!);
        }
      });
    }
  }

  void _loadIntoPlanner() {
    final notifier = ref.read(planProvider.notifier);
    final locations = notifier.completedAsLocations;
    final routeNotifier = ref.read(routeProvider.notifier);
    routeNotifier.clearLocations();
    for (final loc in locations) {
      routeNotifier.addLocation(loc);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RouteOptimizerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);

    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('AI Travel Agent'),
        actions: [
          if (planState.messages.isNotEmpty || planState.completedLocations != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(planProvider.notifier).reset(),
              tooltip: 'Start over',
            ),
        ],
      ),
      body: ChatPanel(
        state: planProvider,
        notifier: planProvider.notifier,
        emptyState: _EmptyState(),
        footerBuilder: (context, state) => state.completedLocations == null
            ? const SizedBox.shrink()
            : _ItineraryBanner(
                summary: state.completedSummary,
                locationCount: state.completedLocations!.length,
                onLoad: _loadIntoPlanner,
                onViewTrip: state.savedTripId == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(tripId: state.savedTripId!),
                          ),
                        ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tell me about your dream trip',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'I\'ll search for places and build an itinerary you can load into the route planner.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _SuggestionChip('2 days in Paris'),
                _SuggestionChip('Museums in Rome'),
                _SuggestionChip('Weekend in Tokyo'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends ConsumerWidget {
  final String text;
  const _SuggestionChip(this.text);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text(text),
      onPressed: () => ref.read(planProvider.notifier).sendMessage(text),
    );
  }
}

class _ItineraryBanner extends StatelessWidget {
  final String? summary;
  final int locationCount;
  final VoidCallback onLoad;
  final VoidCallback? onViewTrip;

  const _ItineraryBanner({
    this.summary,
    required this.locationCount,
    required this.onLoad,
    this.onViewTrip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Itinerary ready — $locationCount locations',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (summary != null && summary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.teal.shade700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // When the trip was saved, opening it is the primary action (it has the
          // full itinerary, bookings, etc.); loading into the route planner stays
          // available as a secondary option. Anonymous sessions have no saved
          // trip, so the planner is their only action.
          if (onViewTrip != null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewTrip,
                icon: const Icon(Icons.luggage),
                label: const Text('View trip'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.map),
                label: const Text('Load into route planner'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.map),
                label: const Text('Load into Planner'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
