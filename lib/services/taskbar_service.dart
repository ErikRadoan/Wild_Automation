import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing taskbar icon overlays and badges
class TaskbarService {
  static final TaskbarService _instance = TaskbarService._internal();
  factory TaskbarService() => _instance;
  TaskbarService._internal();

  String? _overlayIconPath;
  bool _isRunning = false;

  /// Show green dot on taskbar icon to indicate flow is running
  Future<void> showRunningBadge() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // Create green dot overlay icon
      if (_overlayIconPath == null) {
        _overlayIconPath = await _createGreenDotIcon();
      }

      // Set overlay icon (Windows)
      if (Platform.isWindows && _overlayIconPath != null) {
        await windowManager.setIcon(_overlayIconPath!);

        // Also set taskbar progress (green bar/badge effect on Windows)
        await windowManager.setProgressBar(0.5); // Show indeterminate progress

        debugPrint('✓ Taskbar badge shown (flow running)');
      }
    } catch (e) {
      debugPrint('Error showing running badge: $e');
    }
  }

  /// Remove badge from taskbar icon
  Future<void> hideRunningBadge() async {
    if (!_isRunning) return;
    _isRunning = false;

    try {
      // Reset to default icon
      await windowManager.setIcon('assets/wild_automate_logo.png');

      // Clear taskbar progress
      await windowManager.setProgressBar(-1); // -1 removes the progress indicator

      debugPrint('✓ Taskbar badge removed (flow complete)');
    } catch (e) {
      debugPrint('Error hiding running badge: $e');
    }
  }

  /// Create a green dot overlay icon
  Future<String> _createGreenDotIcon() async {
    try {
      // Load the original icon
      final ByteData data = await rootBundle.load('assets/wild_automate_logo.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 256,
        targetHeight: 256,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create a canvas to draw on
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Draw the original icon
      canvas.drawImage(image, Offset.zero, paint);

      // Draw green circle overlay in bottom-right corner
      final greenPaint = Paint()
        ..color = const Color(0xFF00E676) // Vibrant material green
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;

      // Add shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      const radius = 45.0;
      const offset = Offset(256 - radius - 15, 256 - radius - 15);

      // Draw shadow
      canvas.drawCircle(offset.translate(2, 2), radius, shadowPaint);
      // Draw white border
      canvas.drawCircle(offset, radius, borderPaint);
      // Draw green dot
      canvas.drawCircle(offset, radius, greenPaint);

      // Add bright highlight for shimmer effect
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset.translate(-8, -8), radius * 0.3, highlightPaint);

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(256, 256);
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final iconPath = '${tempDir.path}/wild_automate_running.png';
      final file = File(iconPath);
      await file.writeAsBytes(pngBytes!.buffer.asUint8List());

      return iconPath;
    } catch (e) {
      debugPrint('Error creating green dot icon: $e');
      // Return original icon path as fallback
      return 'assets/wild_automate_logo.png';
    }
  }
}

