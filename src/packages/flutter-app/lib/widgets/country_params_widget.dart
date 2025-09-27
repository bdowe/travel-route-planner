import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryParamsWidget extends StatelessWidget {
  final String? startCountry;
  final String? tripStartDate;
  final int? tripDurationDays;
  final String optimizeFor;
  final bool returnToStart;
  final Function(String?) onStartCountryChanged;
  final Function(String?) onTripStartDateChanged;
  final Function(int?) onTripDurationChanged;
  final Function(String) onOptimizeForChanged;
  final Function(bool) onReturnToStartChanged;

  const CountryParamsWidget({
    super.key,
    required this.startCountry,
    required this.tripStartDate,
    required this.tripDurationDays,
    required this.optimizeFor,
    required this.returnToStart,
    required this.onStartCountryChanged,
    required this.onTripStartDateChanged,
    required this.onTripDurationChanged,
    required this.onOptimizeForChanged,
    required this.onReturnToStartChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trip Parameters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Trip Start Date and Duration Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTripStartDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Trip Start Date',
                        prefixIcon: Icon(Icons.flight_takeoff),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        tripStartDate ?? 'Select date',
                        style: TextStyle(
                          color: tripStartDate != null 
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: tripDurationDays?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Trip Duration',
                      hintText: '30',
                      prefixIcon: Icon(Icons.event),
                      suffixText: 'days',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final days = int.tryParse(value);
                      onTripDurationChanged(days);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Start Country and Optimization Strategy Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: startCountry,
                    decoration: const InputDecoration(
                      labelText: 'Start Country Code',
                      hintText: 'US',
                      prefixIcon: Icon(Icons.flight_takeoff),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    ],
                    onChanged: (value) {
                      onStartCountryChanged(value.isEmpty ? null : value.toUpperCase());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: optimizeFor,
                    decoration: const InputDecoration(
                      labelText: 'Optimize For',
                      prefixIcon: Icon(Icons.track_changes),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'distance',
                        child: Text('Distance'),
                      ),
                      DropdownMenuItem(
                        value: 'season',
                        child: Text('Season'),
                      ),
                      DropdownMenuItem(
                        value: 'balanced',
                        child: Text('Balanced'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onOptimizeForChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Return to Start Toggle
            Row(
              children: [
                const Icon(Icons.replay),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return to Starting Country',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'End the trip in the same country where you started',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: returnToStart,
                  onChanged: onReturnToStartChanged,
                ),
              ],
            ),
            
            // Optimization Strategy Info
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimization Strategy: ${_getOptimizationDescription(optimizeFor)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getOptimizationExplanation(optimizeFor),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Clear buttons
            if (tripStartDate != null || startCountry != null || tripDurationDays != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (tripStartDate != null)
                    TextButton.icon(
                      onPressed: () => onTripStartDateChanged(null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Date'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (startCountry != null)
                    TextButton.icon(
                      onPressed: () => onStartCountryChanged(null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Start'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (tripDurationDays != null)
                    TextButton.icon(
                      onPressed: () => onTripDurationChanged(null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Duration'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTripStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tripStartDate != null 
          ? DateTime.tryParse(tripStartDate!) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
    );
    
    if (picked != null) {
      onTripStartDateChanged(picked.toIso8601String().split('T').first);
    }
  }

  String _getOptimizationDescription(String strategy) {
    switch (strategy) {
      case 'distance':
        return 'Distance Optimized';
      case 'season':
        return 'Season Optimized';
      case 'balanced':
        return 'Balanced Optimization';
      default:
        return 'Unknown Strategy';
    }
  }

  String _getOptimizationExplanation(String strategy) {
    switch (strategy) {
      case 'distance':
        return 'Prioritizes shortest travel distances between countries to minimize travel time and costs.';
      case 'season':
        return 'Prioritizes visiting countries during their ideal seasons for the best weather and travel conditions.';
      case 'balanced':
        return 'Balances both distance and seasonal factors to provide an optimal mix of efficiency and ideal travel timing.';
      default:
        return 'No strategy selected.';
    }
  }
}
