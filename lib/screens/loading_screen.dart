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
                  toothHeight: 12, // Bigger teeth
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

/// Custom painter for drawing an industrial gear shape
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

    // Draw industrial gear teeth (rectangular and chunky)
    for (int i = 0; i < teethCount; i++) {
      final angle = (i * 2 * math.pi) / teethCount;
      final nextAngle = ((i + 1) * 2 * math.pi) / teethCount;

      // Tooth width (65% for bigger industrial look)
      final toothAngleWidth = (2 * math.pi) / teethCount * 0.65;

      // Inner arc points
      final innerStart = Offset(
        center.dx + radius * math.cos(angle + toothAngleWidth * 0.15),
        center.dy + radius * math.sin(angle + toothAngleWidth * 0.15),
      );
      final innerEnd = Offset(
        center.dx + radius * math.cos(angle + toothAngleWidth * 0.85),
        center.dy + radius * math.sin(angle + toothAngleWidth * 0.85),
      );

      // Outer arc points (rectangular tooth profile)
      final outerStart = Offset(
        center.dx + outerRadius * math.cos(angle + toothAngleWidth * 0.2),
        center.dy + outerRadius * math.sin(angle + toothAngleWidth * 0.2),
      );
      final outerEnd = Offset(
        center.dx + outerRadius * math.cos(angle + toothAngleWidth * 0.8),
        center.dy + outerRadius * math.sin(angle + toothAngleWidth * 0.8),
      );

      // Gap between teeth
      final gapStart = Offset(
        center.dx + radius * math.cos(angle + toothAngleWidth * 0.85),
        center.dy + radius * math.sin(angle + toothAngleWidth * 0.85),
      );
      final gapEnd = Offset(
        center.dx + radius * math.cos(nextAngle + toothAngleWidth * 0.15),
        center.dy + radius * math.sin(nextAngle + toothAngleWidth * 0.15),
      );

      if (i == 0) {
        path.moveTo(innerStart.dx, innerStart.dy);
      }

      // Draw tooth
      path.lineTo(outerStart.dx, outerStart.dy);
      path.lineTo(outerEnd.dx, outerEnd.dy);
      path.lineTo(innerEnd.dx, innerEnd.dy);

      // Arc to next tooth
      path.arcToPoint(
        gapEnd,
        radius: Radius.circular(radius),
      );
    }

    path.close();
    canvas.drawPath(path, paint);

    // Draw outer rim for depth
    final rimPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, rimPaint);

    // Draw center hole with depth
    final holePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, holeRadius, holePaint);

    // Draw center hole border (thicker for industrial look)
    final holeBorderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, holeRadius, holeBorderPaint);

    // Draw inner ring for detail
    final innerRingPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, holeRadius + 6, innerRingPaint);

    // Draw 6 spokes for industrial detail
    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final start = Offset(
        center.dx + (holeRadius + 6) * math.cos(angle),
        center.dy + (holeRadius + 6) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
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

