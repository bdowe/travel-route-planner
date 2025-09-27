import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/country.dart';
import '../providers/country_provider.dart';
import '../widgets/country_input_dialog.dart';
import '../widgets/country_results_widget.dart';
import '../widgets/country_params_widget.dart';

class CountryOptimizerScreen extends ConsumerWidget {
  const CountryOptimizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryState = ref.watch(countryProvider);
    final countryNotifier = ref.read(countryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Planner'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        actions: [
          if (countryState.countries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                _showClearConfirmation(context, countryNotifier);
              },
              tooltip: 'Clear all countries',
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
                CountryParamsWidget(
                  startCountry: countryState.startCountry,
                  tripStartDate: countryState.tripStartDate,
                  tripDurationDays: countryState.tripDurationDays,
                  optimizeFor: countryState.optimizeFor,
                  returnToStart: countryState.returnToStart,
                  onStartCountryChanged: (country) => countryNotifier.setOptimizationParams(startCountry: country),
                  onTripStartDateChanged: (date) => countryNotifier.setOptimizationParams(tripStartDate: date),
                  onTripDurationChanged: (days) => countryNotifier.setOptimizationParams(tripDurationDays: days),
                  onOptimizeForChanged: (value) => countryNotifier.setOptimizationParams(optimizeFor: value),
                  onReturnToStartChanged: (value) => countryNotifier.setOptimizationParams(returnToStart: value),
                ),
                
                // Countries List Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        MdiIcons.earth,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Countries (${countryState.countries.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showAddCountryDialog(context, countryNotifier),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Country'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Countries List
          if (countryState.countries.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      MdiIcons.earthOff,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No countries added yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add countries to plan your multi-country trip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCountryDialog(context, countryNotifier),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Country'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Countries list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: countryState.countries.length,
                      itemBuilder: (context, index) {
                        final country = countryState.countries[index];
                        return _CountryCard(
                          country: country,
                          index: index,
                          onEdit: () => _showEditCountryDialog(context, countryNotifier, index, country),
                          onDelete: () => countryNotifier.removeCountry(index),
                        );
                      },
                    ),
                  ),
                  
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (countryState.error != null) ...[
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
                                    countryState.error!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: countryNotifier.clearError,
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
                            onPressed: countryState.isLoading ? null : countryNotifier.optimizeCountries,
                            icon: countryState.isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(MdiIcons.earth),
                            label: Text(countryState.isLoading ? 'Optimizing...' : 'Optimize Trip'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).colorScheme.secondary,
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
          if (countryState.response != null)
            CountryResultsWidget(response: countryState.response!),
        ],
      ),
    );
  }

  void _showAddCountryDialog(BuildContext context, CountryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => CountryInputDialog(
        onCountryAdded: notifier.addCountry,
      ),
    );
  }

  void _showEditCountryDialog(BuildContext context, CountryNotifier notifier, int index, Country country) {
    showDialog(
      context: context,
      builder: (context) => CountryInputDialog(
        initialCountry: country,
        onCountryAdded: (updatedCountry) => notifier.updateCountry(index, updatedCountry),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, CountryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Countries'),
        content: const Text('Are you sure you want to clear all countries? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearCountries();
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

class _CountryCard extends StatelessWidget {
  final Country country;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CountryCard({
    required this.country,
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
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            country.code,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          country.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capital: ${country.capital}'),
            Text('Continent: ${country.continent}'),
            Row(
              children: [
                Chip(
                  label: Text(
                    '${country.minStayDays} days min',
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                if (country.idealSeasons.isNotEmpty)
                  Chip(
                    label: Text(
                      '${country.idealSeasons.length} season${country.idealSeasons.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            Text(
              '${country.latitude.toStringAsFixed(2)}, ${country.longitude.toStringAsFixed(2)}',
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
              tooltip: 'Edit country',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Delete country',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
