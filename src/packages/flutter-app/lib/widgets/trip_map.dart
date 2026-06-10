import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../models/itinerary_item.dart';

/// Plots a trip's itinerary on an OpenStreetMap: a numbered, category-tinted pin
/// per place, a route line connecting them in itinerary order, auto-fit to the
/// trip's extent. Tapping a pin calls [onPinTap] with that item's position.
/// When [selectedPosition] changes the camera recenters on that place.
class TripMap extends StatefulWidget {
  final List<ItineraryItem> items;
  final int? selectedPosition;
  final void Function(int position)? onPinTap;

  /// Label text (e.g. "12 min") for the within-city leg leaving the item at the
  /// given position. Drawn at the midpoint of that segment. Empty => no labels.
  final Map<int, String> segmentLabels;

  const TripMap({
    super.key,
    required this.items,
    this.selectedPosition,
    this.onPinTap,
    this.segmentLabels = const {},
  });

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  final MapController _controller = MapController();

  static bool _hasCoords(ItineraryItem i) =>
      i.latitude != 0 || i.longitude != 0;

  /// The coordinate of the currently selected itinerary item, if mappable.
  LatLng? _selectedPoint() {
    final sel = widget.selectedPosition;
    if (sel == null) return null;
    for (final it in widget.items) {
      if (it.position == sel && _hasCoords(it)) {
        return LatLng(it.latitude, it.longitude);
      }
    }
    return null;
  }

  /// Frames the camera on the whole trip, mirroring the initial fit in [build] so
  /// the reset button returns to the opening view. Called from a button tap when
  /// the controller is already live, so it runs synchronously (a post-frame
  /// deferral would not fire without a frame being scheduled).
  void _fitToTrip(List<LatLng> points) {
    if (points.isEmpty) return;
    try {
      if (points.length == 1) {
        _controller.move(points.first, 13);
      } else {
        _controller.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(32),
          ),
        );
      }
    } catch (_) {}
  }

  void _zoomBy(double delta) {
    try {
      _controller.move(
        _controller.camera.center,
        _controller.camera.zoom + delta,
      );
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPosition != null &&
        widget.selectedPosition != oldWidget.selectedPosition) {
      final target = _selectedPoint();
      if (target == null) return;
      // Defer until after layout so the map controller is ready; zoom in enough
      // to break the place out of any marker cluster.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var zoom = 15.0;
        try {
          zoom = _controller.camera.zoom < 15 ? 15 : _controller.camera.zoom;
        } catch (_) {}
        _controller.move(target, zoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mapped = <({ItineraryItem item, LatLng point})>[];
    for (final it in widget.items) {
      if (_hasCoords(it)) {
        mapped.add((item: it, point: LatLng(it.latitude, it.longitude)));
      }
    }

    if (mapped.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Text(
          'No mapped places',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final points = mapped.map((m) => m.point).toList();
    final selected = _selectedPoint();

    // Travel-time labels at the midpoint of each within-city leg (only between
    // truly adjacent itinerary stops that are both mapped).
    final labelMarkers = <Marker>[];
    for (var k = 0; k < mapped.length - 1; k++) {
      final a = mapped[k];
      final b = mapped[k + 1];
      if (b.item.position != a.item.position + 1) continue;
      final label = widget.segmentLabels[a.item.position];
      if (label == null) continue;
      labelMarkers.add(
        Marker(
          point: LatLng(
            (a.point.latitude + b.point.latitude) / 2,
            (a.point.longitude + b.point.longitude) / 2,
          ),
          width: 70,
          height: 22,
          child: _SegmentLabel(text: label),
        ),
      );
    }

    // Wheel scroll stays with the page (the map lives inside a ListView);
    // zooming is done via the on-map buttons or touch pinch.
    const interaction = InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom,
    );

    // Center on the selected place when one is set (e.g. the map was just
    // (re)built after a list tap); otherwise fit the whole trip.
    final MapOptions options = selected != null
        ? MapOptions(
            initialCenter: selected,
            initialZoom: 15,
            interactionOptions: interaction,
          )
        : points.length == 1
            // Single point: bounds collapse, so center with a sensible zoom.
            ? MapOptions(
                initialCenter: points.first,
                initialZoom: 13,
                interactionOptions: interaction,
              )
            : MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(32),
                ),
                interactionOptions: interaction,
              );

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: options,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.travelrouteplanner.app',
            ),
            if (points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 3,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            if (labelMarkers.isNotEmpty) MarkerLayer(markers: labelMarkers),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(40, 40),
                padding: const EdgeInsets.all(40),
                markers: [
                  for (final m in mapped)
                    Marker(
                      point: m.point,
                      width: 32,
                      height: 32,
                      child: _Pin(
                        label: '${m.item.position + 1}',
                        category: m.item.category,
                        selected: widget.selectedPosition == m.item.position,
                        onTap: widget.onPinTap == null
                            ? null
                            : () => widget.onPinTap!(m.item.position),
                      ),
                    ),
                ],
                builder: (context, clusterMarkers) =>
                    _ClusterBubble(count: clusterMarkers.length),
              ),
            ),
          ],
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapButton(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onTap: () => _zoomBy(1),
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onTap: () => _zoomBy(-1),
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: Icons.center_focus_strong,
                tooltip: 'Reset map',
                onTap: () => _fitToTrip(points),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small circular control overlaid on the map (zoom in/out, reset).
class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// A small pill showing a leg's travel time, centered on the route line.
class _SegmentLabel extends StatelessWidget {
  final String text;
  const _SegmentLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  final int count;
  const _ClusterBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final String label;
  final String? category;
  final bool selected;
  final VoidCallback? onTap;

  const _Pin({
    required this.label,
    required this.category,
    required this.selected,
    this.onTap,
  });

  Color _color(ColorScheme scheme) {
    switch (category) {
      case 'restaurant':
        return Colors.deepOrange;
      case 'attraction':
        return scheme.primary;
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : color.withValues(alpha: 0.0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.4 : 0.25),
              blurRadius: selected ? 6 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
