import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/virtues')) return 1;
    if (location.startsWith('/reflections')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _getIndex(context);
    // Adaptive bottom bar height based on safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 60.0 + bottomPadding;

    return Scaffold(
      body: child,
      floatingActionButton: Container(
        height: 60, width: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [KarmaColors.primary, KarmaColors.accent]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: KarmaColors.primary.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/voice-log'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.mic, size: 26, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: navBarHeight,
        decoration: BoxDecoration(
          color: KarmaColors.surface,
          border: Border(top: BorderSide(color: KarmaColors.surfaceLighter.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.only(bottom: bottomPadding),
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded, label: 'Home', selected: index == 0, onTap: () => context.go('/home')),
              _NavItem(icon: Icons.auto_awesome, label: 'Virtues', selected: index == 1, onTap: () => context.go('/virtues')),
              const SizedBox(width: 48), // Space for FAB
              _NavItem(icon: Icons.self_improvement, label: 'Reflect', selected: index == 2, onTap: () => context.go('/reflections')),
              _NavItem(icon: Icons.person, label: 'Profile', selected: index == 3, onTap: () => context.go('/profile')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, size: 22, color: selected ? KarmaColors.primary : KarmaColors.textHint),
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: selected ? KarmaColors.primary : KarmaColors.textHint, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
