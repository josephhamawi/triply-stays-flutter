import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated liquid orb widget with flowing gradient effect
class LiquidOrb extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Widget? child;
  final Duration animationDuration;

  const LiquidOrb({
    super.key,
    this.size = 40,
    this.primaryColor = const Color(0xFF4ECDC4), // Teal/cyan
    this.secondaryColor = const Color(0xFF2D8B7A), // Darker teal
    this.tertiaryColor = const Color(0xFF1A5F52), // Deep teal
    this.child,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<LiquidOrb> createState() => _LiquidOrbState();
}

class _LiquidOrbState extends State<LiquidOrb>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for the gradient
    _rotationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();

    // Pulse animation for organic feel
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: CustomPaint(
                painter: _LiquidPainter(
                  animation: _rotationController.value,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor,
                  tertiaryColor: widget.tertiaryColor,
                ),
                child: Center(child: widget.child),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  _LiquidPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Animated gradient center point
    final angle1 = animation * 2 * math.pi;
    final angle2 = (animation * 2 * math.pi) + (math.pi / 2);
    final angle3 = (animation * 2 * math.pi) + math.pi;

    // Create multiple overlapping gradients for liquid effect
    final gradient1Center = Offset(
      center.dx + math.cos(angle1) * radius * 0.3,
      center.dy + math.sin(angle1) * radius * 0.3,
    );

    final gradient2Center = Offset(
      center.dx + math.cos(angle2) * radius * 0.25,
      center.dy + math.sin(angle2) * radius * 0.25,
    );

    final gradient3Center = Offset(
      center.dx + math.cos(angle3) * radius * 0.2,
      center.dy + math.sin(angle3) * radius * 0.2,
    );

    // Base gradient
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (gradient1Center.dx - center.dx) / radius,
          (gradient1Center.dy - center.dy) / radius,
        ),
        radius: 1.2,
        colors: [
          primaryColor,
          secondaryColor,
          tertiaryColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, basePaint);

    // Overlay gradient 1 - creates flowing effect
    final overlay1Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (gradient2Center.dx - center.dx) / radius,
          (gradient2Center.dy - center.dy) / radius,
        ),
        radius: 0.8,
        colors: [
          primaryColor.withOpacity(0.6),
          secondaryColor.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, overlay1Paint);

    // Overlay gradient 2 - adds depth
    final overlay2Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (gradient3Center.dx - center.dx) / radius,
          (gradient3Center.dy - center.dy) / radius,
        ),
        radius: 0.6,
        colors: [
          Colors.white.withOpacity(0.3),
          primaryColor.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, overlay2Paint);

    // Highlight for 3D effect
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, highlightPaint);
  }

  @override
  bool shouldRepaint(_LiquidPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
