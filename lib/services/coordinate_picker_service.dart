import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'dart:async';

/// Service for picking screen coordinates using main window overlay
class CoordinatePickerService {
  static Completer<Point?>? _completer;
  static OverlayEntry? _overlayEntry;

  // Store original window state
  static Rect? _originalBounds;
  static bool _wasAlwaysOnTop = false;

  /// Pick a coordinate by showing fullscreen overlay in main window
  static Future<Point?> pickCoordinate(BuildContext context) async {
    if (_completer != null) {
      debugPrint('Coordinate picker already active');
      return null;
    }

    try {
      _completer = Completer<Point?>();

      // Get screen dimensions
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenSize = primaryDisplay.size;

      // Save current window state
      _originalBounds = await windowManager.getBounds();
      _wasAlwaysOnTop = await windowManager.isAlwaysOnTop();

      // Make window fullscreen, frameless, always on top, and transparent
      await windowManager.setFullScreen(true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setOpacity(0.3); // Make window transparent
      await windowManager.focus();

      // Show overlay
      _overlayEntry = OverlayEntry(
        builder: (context) => _CoordinatePickerOverlay(
          onCoordinateSelected: (point) {
            _completer?.complete(point);
            _cleanup();
          },
          onCancel: () {
            _completer?.complete(null);
            _cleanup();
          },
          screenWidth: screenSize.width,
          screenHeight: screenSize.height,
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);

      // Wait for result
      final result = await _completer!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _cleanup();
          return null;
        },
      );

      return result;
    } catch (e) {
      debugPrint('Error picking coordinate: $e');
      _cleanup();
      return null;
    }
  }

  static Future<void> _cleanup() async {
    // Remove overlay
    _overlayEntry?.remove();
    _overlayEntry = null;
    _completer = null;

    // Restore window state
    if (_originalBounds != null) {
      await windowManager.setFullScreen(false);
      await windowManager.setBounds(_originalBounds!);
      await windowManager.setAlwaysOnTop(_wasAlwaysOnTop);
      await windowManager.setOpacity(1.0); // Restore full opacity
    }

    _originalBounds = null;
  }
}

/// Fullscreen overlay for coordinate picking
class _CoordinatePickerOverlay extends StatefulWidget {
  final Function(Point) onCoordinateSelected;
  final VoidCallback onCancel;
  final double screenWidth;
  final double screenHeight;

  const _CoordinatePickerOverlay({
    required this.onCoordinateSelected,
    required this.onCancel,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<_CoordinatePickerOverlay> createState() => _CoordinatePickerOverlayState();
}

class _CoordinatePickerOverlayState extends State<_CoordinatePickerOverlay> {
  int? _mouseX;
  int? _mouseY;
  double _devicePixelRatio = 1.0;

  @override
  void initState() {
    super.initState();
    // Get the device pixel ratio (DPI scaling factor)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          debugPrint('[CoordinatePicker] Device pixel ratio: $_devicePixelRatio');
          debugPrint('[CoordinatePicker] Screen size (logical): ${widget.screenWidth}x${widget.screenHeight}');
          debugPrint('[CoordinatePicker] Screen size (physical): ${(widget.screenWidth * _devicePixelRatio).toInt()}x${(widget.screenHeight * _devicePixelRatio).toInt()}');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Fully transparent background
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            // Convert Flutter's logical pixels to physical screen pixels
            // Flutter gives us coordinates in logical pixels (affected by DPI scaling)
            // We need actual screen pixels for OCR
            _mouseX = (event.position.dx * _devicePixelRatio).toInt();
            _mouseY = (event.position.dy * _devicePixelRatio).toInt();
          });
        },
        child: GestureDetector(
          onTap: () {
            if (_mouseX != null && _mouseY != null) {
              debugPrint('[CoordinatePicker] Selected coordinates: ($_mouseX, $_mouseY) [physical pixels]');
              debugPrint('[CoordinatePicker] Device pixel ratio used: $_devicePixelRatio');
              widget.onCoordinateSelected(Point(_mouseX!, _mouseY!));
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Instructions - Opaque background
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF56585C), // Solid opaque color
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Click to select coordinate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_mouseX != null && _mouseY != null)
                          Column(
                            children: [
                              Text(
                                'Screen Position: ($_mouseX, $_mouseY)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                              ),
                              if (_devicePixelRatio != 1.0)
                                Text(
                                  'DPI Scale: ${(_devicePixelRatio * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: widget.onCancel,
                          child: const Text(
                            'Cancel (ESC)',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Crosshair - Opaque and highly visible
              // Position based on logical pixels (for display), but report physical pixels (for OCR)
              if (_mouseX != null && _mouseY != null)
                Positioned(
                  left: (_mouseX! / _devicePixelRatio) - 15,
                  top: (_mouseY! / _devicePixelRatio) - 15,
                  child: IgnorePointer(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 3),
                        color: Colors.red.withValues(alpha: 0.3), // Slight fill for visibility
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.red, size: 20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  String toString() => '($x, $y)';
}

