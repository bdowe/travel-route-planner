import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/location.dart';
import '../providers/route_provider.dart';
import '../widgets/location_input_dialog.dart';
import '../widgets/route_results_widget.dart';
import '../widgets/optimization_params_widget.dart';

class RouteOptimizerScreen extends ConsumerWidget {
  const RouteOptimizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final routeNotifier = ref.read(routeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Optimizer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (routeState.locations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                _showClearConfirmation(context, routeNotifier);
              },
              tooltip: 'Clear all locations',
            ),
        ],
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Optimization Parameters
                OptimizationParamsWidget(
                  startTime: routeState.startTime,
                  startDate: routeState.startDate,
                  returnToStart: routeState.returnToStart,
                  onStartTimeChanged: (time) => routeNotifier.setOptimizationParams(startTime: time),
                  onStartDateChanged: (date) => routeNotifier.setOptimizationParams(startDate: date),
                  onReturnToStartChanged: (value) => routeNotifier.setOptimizationParams(returnToStart: value),
                ),
                
                // Locations List Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        MdiIcons.mapMarkerMultiple,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Locations (${routeState.locations.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showAddLocationDialog(context, routeNotifier),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Location'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Locations List
          if (routeState.locations.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      MdiIcons.mapMarkerOff,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No locations added yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add locations to optimize your route',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddLocationDialog(context, routeNotifier),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Location'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Locations list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: routeState.locations.length,
                      itemBuilder: (context, index) {
                        final location = routeState.locations[index];
                        return _LocationCard(
                          location: location,
                          index: index,
                          onEdit: () => _showEditLocationDialog(context, routeNotifier, index, location),
                          onDelete: () => routeNotifier.removeLocation(index),
                        );
                      },
                    ),
                  ),
                  
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (routeState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    routeState.error!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: routeNotifier.clearError,
                                  icon: Icon(
                                    Icons.close,
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: routeState.isLoading ? null : routeNotifier.optimizeRoute,
                            icon: routeState.isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(MdiIcons.routes),
                            label: Text(routeState.isLoading ? 'Optimizing...' : 'Optimize Route'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Results Section
          if (routeState.response != null)
            RouteResultsWidget(response: routeState.response!),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, RouteNotifier notifier) async {
    final result = await showDialog<Location>(
      context: context,
      builder: (context) => LocationInputDialog(
        onLocationAdded: notifier.addLocation,
      ),
    );
    
    if (result != null) {
      notifier.addLocation(result);
    }
  }

  void _showEditLocationDialog(BuildContext context, RouteNotifier notifier, int index, Location location) async {
    final result = await showDialog<Location>(
      context: context,
      builder: (context) => LocationInputDialog(
        initialLocation: location,
        onLocationAdded: (updatedLocation) => notifier.updateLocation(index, updatedLocation),
      ),
    );
    
    if (result != null) {
      notifier.updateLocation(index, result);
    }
  }

  void _showClearConfirmation(BuildContext context, RouteNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Locations'),
        content: const Text('Are you sure you want to clear all locations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearLocations();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Location location;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationCard({
    required this.location,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.address != null)
              Text(location.address!),
            Row(
              children: [
                if (location.category != null) ...[
                  Chip(
                    label: Text(
                      location.category!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                ],
                if (location.visitDurationMinutes != null)
                  Chip(
                    label: Text(
                      '${location.visitDurationMinutes} min',
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            Text(
              '${location.latitude?.toStringAsFixed(4) ?? 'N/A'}, ${location.longitude?.toStringAsFixed(4) ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit location',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Delete location',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
