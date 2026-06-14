import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level destinations. Keeping it to three keeps the choice trivial
/// (Hick's Law) and puts the chat and saved trips one tap away instead of
/// buried in a menu.
enum AppTab { home, plan, trips }

/// The selected top-level tab. A provider (rather than local state) so any
/// screen — e.g. the home hero, or a pushed page's nav rail — can switch tabs
/// without prop-drilling callbacks.
final navIndexProvider = StateProvider<int>((ref) => AppTab.home.index);

/// One nav destination's display data. Shared so the shell's rail and bar render
/// the exact same set, in lockstep.
class NavDestinationData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavDestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// The single source of truth for the three top-level destinations, ordered to
/// match [AppTab].
const List<NavDestinationData> navDestinations = [
  NavDestinationData(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  NavDestinationData(
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
    label: 'Plan',
  ),
  NavDestinationData(
    icon: Icons.luggage_outlined,
    selectedIcon: Icons.luggage,
    label: 'Trips',
  ),
];

/// Width at or above which the persistent rail (rather than a bottom bar) is
/// shown.
const double kRailBreakpoint = 800;
