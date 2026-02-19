import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Main shell with glassmorphism bottom navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _isNavigating = false; // Prevent double updates during navigation

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Explore',
      path: '/home',
    ),
    _NavItem(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
      label: 'AI',
      path: '/ai',
    ),
    // Placeholder for center FAB
    _NavItem(
      icon: Icons.add,
      activeIcon: Icons.add,
      label: '',
      path: '',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Messages',
      path: '/messages',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      path: '/profile',
    ),
  ];

  void _onNavTap(int index) {
    if (_currentIndex == index || _isNavigating) return;
    _isNavigating = true;
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
    // Reset flag after navigation completes
    Future.microtask(() {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndexFromLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndexFromLocation();
  }

  void _updateIndexFromLocation() {
    // Skip if we're in the middle of programmatic navigation
    if (_isNavigating) return;

    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (_navItems[i].path.isNotEmpty && location.startsWith(_navItems[i].path)) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);
        }
        break;
      }
    }
  }

  void _onAddTap() {
    // Navigate to add listing screen
    context.push('/add-listing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: _GlassBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onAddTap: _onAddTap,
      ),
    );
  }
}

/// Navigation item data
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

/// Glassmorphism bottom navigation bar with curved notch and center FAB
class _GlassBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddTap;

  const _GlassBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Shadow layer
          Positioned.fill(
            child: CustomPaint(
              painter: _NotchedBarPainter(),
            ),
          ),
          // Frosted glass background (transparent)
          Positioned.fill(
            child: ClipPath(
              clipper: _NotchedClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // Nav items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              items.length,
              (index) {
                // Center item is a spacer for the FAB
                if (index == 2) {
                  return const SizedBox(width: 72);
                }
                return _NavButton(
                  item: items[index],
                  isSelected: currentIndex == index,
                  onTap: () => onTap(index),
                );
              },
            ),
          ),
          // Floating Add Button
          Positioned(
            top: -22,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryOrange,
                      Color(0xFFFF8A50),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds the notched navigation bar path (shared by painter and clipper)
Path _buildNotchedPath(Size size) {
    const cr = 28.0; // corner radius
    final cx = size.width / 2;

    // FAB geometry: 58px button at top: -22
    const fabRadius = 29.0;
    const gap = 5.0;
    const r = fabRadius + gap; // 34 - notch arc radius
    const fabCenterY = 7.0; // FAB center Y in bar coords (-22 + 29)

    // Adapted from Flutter's CircularNotchedRectangle algorithm
    const s1 = 15.0; // approach distance
    const s2 = 1.0; // tightness
    const a = -1.0 * r - s2; // -35
    const b = -fabCenterY; // -7

    final n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final p2yA = math.sqrt(math.max(0, r * r - p2xA * p2xA));
    final p2yB = math.sqrt(math.max(0, r * r - p2xB * p2xB));

    const cmp = b < 0 ? -1.0 : 1.0;
    final p2 =
        cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

    // Points relative to FAB center, then translated to bar coords
    final fabCenter = Offset(cx, fabCenterY);
    final pp0 = Offset(a - s1, b) + fabCenter;
    final pp1 = Offset(a, b) + fabCenter;
    final pp2 = p2 + fabCenter;
    final pp3 = Offset(-p2.dx, p2.dy) + fabCenter;
    final pp4 = Offset(-a, b) + fabCenter;
    final pp5 = Offset(-a + s1, b) + fabCenter;

    final path = Path()
      ..moveTo(0, cr)
      ..quadraticBezierTo(0, 0, cr, 0)
      ..lineTo(pp0.dx, pp0.dy)
      ..quadraticBezierTo(pp1.dx, pp1.dy, pp2.dx, pp2.dy)
      ..arcToPoint(pp3, radius: Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(pp4.dx, pp4.dy, pp5.dx, pp5.dy)
      ..lineTo(size.width - cr, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cr)
      ..lineTo(size.width, size.height - cr)
      ..quadraticBezierTo(
          size.width, size.height, size.width - cr, size.height)
      ..lineTo(cr, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cr)
      ..close();

    return path;
}

/// Custom clipper using the notched path for glassmorphism
class _NotchedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _buildNotchedPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom painter for the notched navigation bar shadow and border
class _NotchedBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildNotchedPath(size);

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.15), 16, true);

    // Draw subtle border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Individual navigation button
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
