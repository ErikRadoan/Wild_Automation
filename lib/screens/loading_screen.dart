import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Loading screen with gear animation shown during app initialization
class LoadingScreen extends StatefulWidget {
  final String? message;

  const LoadingScreen({
    super.key,
    this.message,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gear
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(120, 120),
                painter: GearPainter(
                  color: const Color(0xFF56585C),
                  teethCount: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // App title
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'WILD',
                    style: TextStyle(
                      color: Color(0xFF56585C),
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  TextSpan(
                    text: ' Automate',
                    style: TextStyle(
                      color: Color(0xFFB5B7BB),
                      fontSize: 32,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Loading message
            if (widget.message != null)
              Text(
                widget.message!,
                style: const TextStyle(
                  color: Color(0xFFB5B7BB),
                  fontSize: 14,
                ),
              )
            else
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Color(0xFFB5B7BB),
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 24),
            // Progress indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: const Color(0xFF2D2D30),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56585C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for drawing a gear shape
class GearPainter extends CustomPainter {
  final Color color;
  final int teethCount;
  final double toothHeight;
  final double holeRadius;

  GearPainter({
    required this.color,
    this.teethCount = 12,
    this.toothHeight = 8,
    this.holeRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - toothHeight;
    final outerRadius = radius + toothHeight;

    final path = Path();

    // Draw gear teeth
    for (int i = 0; i < teethCount; i++) {
      final angle = (i * 2 * math.pi) / teethCount;
      final nextAngle = ((i + 1) * 2 * math.pi) / teethCount;

      // Tooth base (inner)
      final toothBaseStart = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Tooth top (outer) - narrower than base
      final toothAngleWidth = (2 * math.pi) / teethCount * 0.4;
      final toothTopStart = Offset(
        center.dx + outerRadius * math.cos(angle + toothAngleWidth * 0.3),
        center.dy + outerRadius * math.sin(angle + toothAngleWidth * 0.3),
      );
      final toothTopEnd = Offset(
        center.dx + outerRadius * math.cos(angle + toothAngleWidth * 0.7),
        center.dy + outerRadius * math.sin(angle + toothAngleWidth * 0.7),
      );

      // Tooth base end
      final toothBaseEnd = Offset(
        center.dx + radius * math.cos(nextAngle),
        center.dy + radius * math.sin(nextAngle),
      );

      if (i == 0) {
        path.moveTo(toothBaseStart.dx, toothBaseStart.dy);
      } else {
        path.lineTo(toothBaseStart.dx, toothBaseStart.dy);
      }

      path.lineTo(toothTopStart.dx, toothTopStart.dy);
      path.lineTo(toothTopEnd.dx, toothTopEnd.dy);
      path.lineTo(toothBaseEnd.dx, toothBaseEnd.dy);
    }

    path.close();
    canvas.drawPath(path, paint);

    // Draw center hole
    final holePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, holeRadius, holePaint);

    // Draw center hole border
    final holeBorderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, holeRadius, holeBorderPaint);

    // Draw some spokes for detail
    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi) / 2;
      final start = Offset(
        center.dx + holeRadius * math.cos(angle),
        center.dy + holeRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      canvas.drawLine(start, end, spokePaint);
    }
  }

  @override
  bool shouldRepaint(GearPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.teethCount != teethCount ||
        oldDelegate.toothHeight != toothHeight ||
        oldDelegate.holeRadius != holeRadius;
  }
}

