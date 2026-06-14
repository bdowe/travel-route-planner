import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/app_nav.dart';
import 'home_screen.dart';
import 'agent_screen.dart';
import 'trips_list_screen.dart';

/// Persistent navigation shell. The rail (wide) / bar (narrow) lives here,
/// outside the per-tab navigators, so it never moves when a page is pushed —
/// only the content area animates. Each tab keeps its own push stack, so a trip
/// opened in one tab stays put when you switch away and back.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // One navigator per tab. Pushes from inside a tab resolve to its navigator
  // (via the ambient `Navigator.of(context)`), animating only the content
  // region rather than the whole screen.
  late final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(AppTab.values.length, (_) => GlobalKey<NavigatorState>());

  static const List<Widget> _tabRoots = [
    HomeScreen(),
    AgentScreen(),
    TripsListScreen(),
  ];

  void _onSelect(int i) {
    final current = ref.read(navIndexProvider);
    if (i == current) {
      // Tapping the active tab again returns it to its root.
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      ref.read(navIndexProvider.notifier).state = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final isWide = MediaQuery.sizeOf(context).width >= kRailBreakpoint;

    // The root navigator only holds the shell, so forward a system/browser back
    // to the active tab's navigator — otherwise nested pushes (trip detail, etc.)
    // couldn't be dismissed with the back button. At a tab root this is a no-op.
    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navKeys[ref.read(navIndexProvider)].currentState?.maybePop();
      },
      child: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < _tabRoots.length; i++)
            _TabNavigator(navKey: _navKeys[i], child: _tabRoots[i]),
        ],
      ),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in navDestinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in navDestinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// A tab's own [Navigator]: its root route is the tab screen; in-app pushes from
/// within the tab stack here so they animate inside the content area only.
class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;
  final Widget child;

  const _TabNavigator({required this.navKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => child,
        settings: settings,
      ),
    );
  }
}
