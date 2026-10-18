import 'package:flutter/material.dart';
import 'package:worktrace/app/navigation/app_destinations.dart';
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/features/home/home_screen.dart';
import 'package:worktrace/features/snippets/snippets_screen.dart';
import 'package:worktrace/features/tasks/tasks_screen.dart';

/// Responsive application shell with tab navigation.
///
/// Uses [NavigationBar] on compact screens (< 600 dp) and
/// [NavigationRail] on wider screens. Navigation state is local
/// to this widget — no external state management is needed for
/// simple tab selection.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    TasksScreen(),
    SnippetsScreen(),
  ];

  /// Width threshold for switching between compact and wide layout.
  static const double _railBreakpoint = 600;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
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
              return _buildWideLayout();
            }
            return _buildCompactLayout();
          },
        ),
      ),
    );
  }

  /// Compact layout: content area + bottom NavigationBar.
  Widget _buildCompactLayout() {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
        NavigationBar(
          selectedIndex: _selectedIndex,
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
  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
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
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ],
    );
  }
}
