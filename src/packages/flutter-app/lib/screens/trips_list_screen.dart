import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_app_bar.dart';
import '../providers/trips_provider.dart';
import 'trip_detail_screen.dart';

class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripsProvider.notifier).loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tripsProvider);

    Widget body;
    if (state.loading && state.trips.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.trips.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Could not load trips', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(tripsProvider.notifier).loadTrips(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state.trips.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.luggage, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('No trips yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Chat with the AI agent to create your first trip.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(tripsProvider.notifier).loadTrips(),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: state.trips.length,
          itemBuilder: (context, i) {
            final trip = state.trips[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(trip.title),
                subtitle: Text('${trip.status} · created ${_shortDate(trip.createdAt)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const GradientAppBar(
        title: Text('My Trips'),
      ),
      body: body,
    );
  }

  String _shortDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
