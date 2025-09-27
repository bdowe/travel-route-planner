import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/country.dart';
import '../models/season.dart';

class CountryInputDialog extends StatefulWidget {
  final Country? initialCountry;
  final Function(Country) onCountryAdded;

  const CountryInputDialog({
    super.key,
    this.initialCountry,
    required this.onCountryAdded,
  });

  @override
  State<CountryInputDialog> createState() => _CountryInputDialogState();
}

class _CountryInputDialogState extends State<CountryInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _capitalController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _minStayDaysController = TextEditingController();
  final _currencyController = TextEditingController();
  
  String? _selectedContinent;
  List<Season> _idealSeasons = [];
  List<int> _avoidMonths = [];

  static const List<String> _continents = [
    'Africa',
    'Antarctica', 
    'Asia',
    'Europe',
    'North America',
    'Oceania',
    'South America',
  ];

  static const Map<int, String> _monthNames = {
    1: 'January',
    2: 'February', 
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialCountry != null) {
      final country = widget.initialCountry!;
      _codeController.text = country.code;
      _nameController.text = country.name;
      _capitalController.text = country.capital;
      _latitudeController.text = country.latitude.toString();
      _longitudeController.text = country.longitude.toString();
      _minStayDaysController.text = country.minStayDays.toString();
      _currencyController.text = country.currency;
      _selectedContinent = country.continent;
      _idealSeasons = List.from(country.idealSeasons);
      _avoidMonths = List.from(country.avoidMonths);
    } else {
      // Set some defaults
      _minStayDaysController.text = '7';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _capitalController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _minStayDaysController.dispose();
    _currencyController.dispose();
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
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.initialCountry != null ? 'Edit Country' : 'Add Country',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSecondary,
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
                        // Country code and name row
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Code *',
                                  hintText: 'US',
                                  prefixIcon: Icon(Icons.flag),
                                ),
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(3),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 2) {
                                    return 'Min 2 chars';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Country Name *',
                                  hintText: 'United States',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Country name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Capital and continent row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _capitalController,
                                decoration: const InputDecoration(
                                  labelText: 'Capital *',
                                  hintText: 'Washington, D.C.',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Capital is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedContinent,
                                decoration: const InputDecoration(
                                  labelText: 'Continent *',
                                  prefixIcon: Icon(Icons.language),
                                ),
                                items: _continents.map((continent) {
                                  return DropdownMenuItem(
                                    value: continent,
                                    child: Text(continent),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedContinent = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a continent';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
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
                                  hintText: '39.8283',
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
                                  hintText: '-98.5795',
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
                        
                        // Min stay days and currency row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _minStayDaysController,
                                decoration: const InputDecoration(
                                  labelText: 'Min Stay Days *',
                                  hintText: '7',
                                  prefixIcon: Icon(Icons.event),
                                  suffixText: 'days',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final days = int.tryParse(value);
                                  if (days == null || days <= 0) {
                                    return 'Must be positive';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _currencyController,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  hintText: 'USD',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(3),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Ideal seasons section
                        Text(
                          'Ideal Travel Seasons',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add seasons when this country is ideal to visit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ..._idealSeasons.map((season) => Chip(
                              label: Text(season.name),
                              onDeleted: () {
                                setState(() {
                                  _idealSeasons.remove(season);
                                });
                              },
                            )),
                            ActionChip(
                              label: const Text('Add Season'),
                              onPressed: _addIdealSeason,
                              avatar: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Avoid months section  
                        Text(
                          'Months to Avoid',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select months when travel should be avoided',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: _monthNames.entries.map((entry) {
                            final isSelected = _avoidMonths.contains(entry.key);
                            return FilterChip(
                              label: Text(entry.value),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _avoidMonths.add(entry.key);
                                  } else {
                                    _avoidMonths.remove(entry.key);
                                  }
                                });
                              },
                            );
                          }).toList(),
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
                    onPressed: _saveCountry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: Text(widget.initialCountry != null ? 'Update' : 'Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addIdealSeason() {
    showDialog(
      context: context,
      builder: (context) => _SeasonInputDialog(
        onSeasonAdded: (season) {
          setState(() {
            _idealSeasons.add(season);
          });
        },
      ),
    );
  }

  void _saveCountry() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final country = Country(
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      capital: _capitalController.text.trim(),
      latitude: double.parse(_latitudeController.text),
      longitude: double.parse(_longitudeController.text),
      idealSeasons: _idealSeasons,
      avoidMonths: _avoidMonths,
      minStayDays: int.parse(_minStayDaysController.text),
      continent: _selectedContinent!,
      currency: _currencyController.text.trim(),
    );

    widget.onCountryAdded(country);
    Navigator.of(context).pop();
  }
}

class _SeasonInputDialog extends StatefulWidget {
  final Function(Season) onSeasonAdded;

  const _SeasonInputDialog({required this.onSeasonAdded});

  @override
  State<_SeasonInputDialog> createState() => _SeasonInputDialogState();
}

class _SeasonInputDialogState extends State<_SeasonInputDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _startMonth = 1;
  int _endMonth = 3;
  double _score = 8.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ideal Season'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Season Name'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _startMonth,
                  decoration: const InputDecoration(labelText: 'Start Month'),
                  items: List.generate(12, (index) {
                    final month = index + 1;
                    return DropdownMenuItem(
                      value: month,
                      child: Text(_getMonthName(month)),
                    );
                  }),
                  onChanged: (value) => setState(() => _startMonth = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _endMonth,
                  decoration: const InputDecoration(labelText: 'End Month'),
                  items: List.generate(12, (index) {
                    final month = index + 1;
                    return DropdownMenuItem(
                      value: month,
                      child: Text(_getMonthName(month)),
                    );
                  }),
                  onChanged: (value) => setState(() => _endMonth = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Score: ${_score.toStringAsFixed(1)}'),
          Slider(
            value: _score,
            min: 1.0,
            max: 10.0,
            divisions: 90,
            onChanged: (value) => setState(() => _score = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              final season = Season(
                name: _nameController.text,
                description: _descriptionController.text,
                startMonth: _startMonth,
                endMonth: _endMonth,
                score: _score,
              );
              widget.onSeasonAdded(season);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
