import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/aurora_theme.dart';
import 'responsive.dart';

class AdaptiveShell extends StatelessWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.library_books_rounded, activeIcon: Icons.library_books, label: 'Library', path: '/library'),
    (icon: Icons.insights_outlined, activeIcon: Icons.insights, label: 'Activity', path: '/activity'),
    (icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'Knowledge', path: '/knowledge'),
    (icon: Icons.cloud_outlined, activeIcon: Icons.cloud, label: 'Cloud', path: '/cloud'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: '/settings'),
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
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AuroraColors.deepSpace.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_destinations.length, (i) {
                    final dest = _destinations[i];
                    final isActive = selectedIndex == i;
                    return _NavItem(
                      icon: isActive ? dest.activeIcon : dest.icon,
                      label: dest.label,
                      isActive: isActive,
                      onTap: () => _onDestinationSelected(context, i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailShell(BuildContext context) {
    final selectedIndex = _currentIndex(context);
    final extended = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AuroraColors.cosmos.withOpacity(0.9),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationRail(
              selectedIndex: selectedIndex,
              extended: extended,
              backgroundColor: Colors.transparent,
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
              indicatorColor: AuroraColors.auroraTeal.withOpacity(0.12),
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
              destinations: [
                for (final dest in _destinations)
                  NavigationRailDestination(
                    icon: Icon(dest.icon),
                    selectedIcon: Icon(dest.activeIcon),
                    label: Text(dest.label),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isActive
                      ? AuroraColors.auroraTeal.withOpacity(0.15)
                      : _hovering
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isActive
                      ? AuroraColors.auroraTeal
                      : _hovering
                          ? AuroraColors.textSecondary
                          : AuroraColors.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive
                      ? AuroraColors.auroraTeal
                      : AuroraColors.textTertiary,
                  fontSize: 10,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
