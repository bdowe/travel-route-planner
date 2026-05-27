import 'package:flutter/material.dart';
import '../models/location.dart';
import 'place_search_dialog.dart';

class LocationInputDialog extends StatelessWidget {
  final Location? initialLocation;
  final Function(Location) onLocationAdded;

  const LocationInputDialog({
    super.key,
    this.initialLocation,
    required this.onLocationAdded,
  });

  @override
  Widget build(BuildContext context) {
    return PlaceSearchDialog(
      initialLocation: initialLocation,
    );
  }
}