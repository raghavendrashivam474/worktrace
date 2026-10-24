import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worktrace/app/navigation/app_destinations.dart';
import 'package:worktrace/app/navigation/navigation_provider.dart';
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/features/home/home_screen.dart';
import 'package:worktrace/features/snippets/snippets_screen.dart';
import 'package:worktrace/features/tasks/tasks_screen.dart';

/// Responsive application shell with tab navigation.
///
/// Uses [NavigationBar] on compact screens (< 600 dp) and
/// [NavigationRail] on wider screens. Navigation index is
/// stored in [navigationIndexProvider] so that child screens
/// (e.g. HomeScreen quick actions) can request tab changes.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const List<Widget> _screens = [
    HomeScreen(),
    TasksScreen(),
    SnippetsScreen(),
  ];

  /// Width threshold for switching between compact and wide layout.
  static const double _railBreakpoint = 600;

  void _onDestinationSelected(int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedIndex != 0) {
          _onDestinationSelected(0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/WorkTrace.png',
                height: 28,
                width: 28,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.route_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Worktrace', style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _railBreakpoint) {
              return _buildWideLayout(selectedIndex);
            }
            return _buildCompactLayout(selectedIndex);
          },
        ),
      ),
    );
  }

  /// Compact layout: content area + bottom NavigationBar.
  Widget _buildCompactLayout(int selectedIndex) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(index: selectedIndex, children: _screens),
        ),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: appDestinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  /// Wide layout: side NavigationRail + content area.
  Widget _buildWideLayout(int selectedIndex) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          labelType: NavigationRailLabelType.all,
          destinations: appDestinations
              .map(
                (d) => NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
              )
              .toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(index: selectedIndex, children: _screens),
        ),
      ],
    );
  }
}
