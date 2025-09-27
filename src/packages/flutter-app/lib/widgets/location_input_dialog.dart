import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/location.dart';
import '../models/operating_hours.dart';

class LocationInputDialog extends StatefulWidget {
  final Location? initialLocation;
  final Function(Location) onLocationAdded;

  const LocationInputDialog({
    super.key,
    this.initialLocation,
    required this.onLocationAdded,
  });

  @override
  State<LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<LocationInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _visitDurationController = TextEditingController();
  
  String? _selectedCategory;
  OperatingHours? _operatingHours;

  static const List<String> _categories = [
    'restaurant',
    'coffee_shop', 
    'museum',
    'park',
    'shopping',
    'attraction',
    'hotel',
    'gas_station',
    'pharmacy',
    'bank',
    'hospital',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      final location = widget.initialLocation!;
      _nameController.text = location.name;
      _addressController.text = location.address ?? '';
      _latitudeController.text = location.latitude.toString();
      _longitudeController.text = location.longitude.toString();
      _visitDurationController.text = location.visitDurationMinutes?.toString() ?? '';
      _selectedCategory = location.category;
      _operatingHours = location.hours;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _visitDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.initialLocation != null ? 'Edit Location' : 'Add Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Location Name *',
                            hintText: 'Enter location name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Location name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Address field
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            hintText: 'Enter full address',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Coordinates row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude *',
                                  hintText: '40.7128',
                                  prefixIcon: Icon(Icons.my_location),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final lat = double.tryParse(value);
                                  if (lat == null || lat < -90 || lat > 90) {
                                    return 'Invalid latitude';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude *',
                                  hintText: '-74.0060',
                                  prefixIcon: Icon(Icons.my_location),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final lng = double.tryParse(value);
                                  if (lng == null || lng < -180 || lng > 180) {
                                    return 'Invalid longitude';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Select category',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(_formatCategoryName(category)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Visit duration
                        TextFormField(
                          controller: _visitDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Visit Duration (minutes)',
                            hintText: '60',
                            prefixIcon: Icon(Icons.timer),
                            suffixText: 'min',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Must be a positive number';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Operating hours (simplified for demo)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Operating Hours',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Note: Operating hours are optional. If not specified, default business hours will be assumed.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _showOperatingHoursDialog,
                                  icon: const Icon(Icons.access_time),
                                  label: Text(_operatingHours != null ? 'Edit Hours' : 'Set Hours'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveLocation,
                    child: Text(widget.initialLocation != null ? 'Update' : 'Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showOperatingHoursDialog() {
    // Simplified operating hours dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Operating Hours'),
        content: const Text(
          'For this demo, we\'ll use default business hours (9:00-17:00). '
          'In a full implementation, you would have a detailed time picker for each day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _operatingHours = const OperatingHours(
                  monday: '09:00-17:00',
                  tuesday: '09:00-17:00',
                  wednesday: '09:00-17:00',
                  thursday: '09:00-17:00',
                  friday: '09:00-17:00',
                  saturday: '10:00-16:00',
                  sunday: 'closed',
                );
              });
              Navigator.of(context).pop();
            },
            child: const Text('Set Default Hours'),
          ),
        ],
      ),
    );
  }

  void _saveLocation() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final location = Location(
      id: widget.initialLocation?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      latitude: double.parse(_latitudeController.text),
      longitude: double.parse(_longitudeController.text),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      category: _selectedCategory,
      visitDurationMinutes: _visitDurationController.text.isEmpty 
          ? null 
          : int.parse(_visitDurationController.text),
      hours: _operatingHours,
    );

    widget.onLocationAdded(location);
    Navigator.of(context).pop();
  }
}
