import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/aurora_theme.dart';
import 'responsive.dart';

class AdaptiveShell extends StatelessWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.library_books, label: 'Library', path: '/library'),
    (icon: Icons.insights, label: 'Activity', path: '/activity'),
    (icon: Icons.hub, label: 'Knowledge', path: '/knowledge'),
    (icon: Icons.cloud, label: 'Cloud', path: '/cloud'),
    (icon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/activity')) return 1;
    if (location.startsWith('/knowledge')) return 2;
    if (location.startsWith('/cloud')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileShell(context);
    }
    return _buildRailShell(context);
  }

  Widget _buildMobileShell(BuildContext context) {
    final selectedIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onDestinationSelected(context, index),
        items: [
          for (final dest in _destinations)
            BottomNavigationBarItem(
              icon: Icon(dest.icon),
              label: dest.label,
            ),
        ],
      ),
    );
  }

  Widget _buildRailShell(BuildContext context) {
    final selectedIndex = _currentIndex(context);
    final extended = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            extended: extended,
            backgroundColor: AuroraColors.cosmos,
            selectedIconTheme: const IconThemeData(
              color: AuroraColors.auroraTeal,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AuroraColors.auroraTeal,
              fontWeight: FontWeight.w600,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AuroraColors.textTertiary,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AuroraColors.textTertiary,
            ),
            indicatorColor: AuroraColors.auroraTeal.withValues(alpha: 0.15),
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            destinations: [
              for (final dest in _destinations)
                NavigationRailDestination(
                  icon: Icon(dest.icon),
                  label: Text(dest.label),
                ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
