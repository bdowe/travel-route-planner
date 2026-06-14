import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

/// The trip detail screen the user last opened, remembered on-device so the
/// home screen can offer a one-tap way back into it. Carries a snapshot of the
/// date range and status so the tile can surface state, not just a name.
class RecentTrip {
  final String tripId;
  final String title;
  final String? dateRange;
  final String status;

  const RecentTrip({
    required this.tripId,
    required this.title,
    this.dateRange,
    this.status = '',
  });
}

class RecentTripNotifier extends StateNotifier<RecentTrip?> {
  /// Signed-in user the stored value belongs to; null when anonymous, in which
  /// case nothing is recorded (trips require sign-in anyway).
  final String? _userId;

  RecentTripNotifier(this._userId) : super(null);

  String get _key => 'recent_trip.$_userId';

  /// Restore the last viewed trip for this user from device storage.
  Future<void> load() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final id = m['id'] as String?;
      final title = m['title'] as String?;
      if (id != null && id.isNotEmpty && title != null) {
        state = RecentTrip(
          tripId: id,
          title: title,
          dateRange: m['dateRange'] as String?,
          status: (m['status'] as String?) ?? '',
        );
      }
    } catch (_) {
      // Malformed value — ignore and stay empty.
    }
  }

  /// Remember [tripId] as the most recently viewed trip. Call after a trip
  /// detail screen successfully loads. [dateRange] and [status] are a snapshot
  /// for the home tile.
  Future<void> record(
    String tripId,
    String title, {
    String? dateRange,
    String status = '',
  }) async {
    if (_userId == null) return;
    state = RecentTrip(
      tripId: tripId,
      title: title,
      dateRange: dateRange,
      status: status,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'id': tripId,
        'title': title,
        if (dateRange != null) 'dateRange': dateRange,
        'status': status,
      }),
    );
  }

  /// Forget the recent trip if it points at [tripId] (used when a trip is
  /// deleted, so the home tile never targets a dead trip).
  Future<void> clearIfMatches(String tripId) async {
    if (_userId == null || state?.tripId != tripId) return;
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Rebuilds on sign-in/out so each user only ever sees their own recent trip.
final recentTripProvider =
    StateNotifierProvider<RecentTripNotifier, RecentTrip?>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return RecentTripNotifier(userId)..load();
});
