import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../models/screen_object.dart';
import 'dart:math' as math;

/// Full-screen overlay showing objects at their actual screen positions
class ObjectPreviewOverlayScreen extends StatefulWidget {
  final List<ScreenObject> objects;

  const ObjectPreviewOverlayScreen({super.key, required this.objects});

  @override
  State<ObjectPreviewOverlayScreen> createState() => _ObjectPreviewOverlayScreenState();
}

class _ObjectPreviewOverlayScreenState extends State<ObjectPreviewOverlayScreen> {
  ScreenObject? _hoveredObject;
  final List<Color> _colors = [
    const Color(0xFF56585C),
    const Color(0xFFB5B7BB),
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _setupFullscreen();
  }

  Future<void> _setupFullscreen() async {
    await windowManager.setFullScreen(true);
  }

  @override
  void dispose() {
    windowManager.setFullScreen(false);
    super.dispose();
  }

  Color _getColorForObject(int index) {
    return _colors[index % _colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
        }
      },
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.4), // 40% transparent gray overlay
        body: Stack(
          children: [
            // Full screen area
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),

            // Draw all objects
            ...widget.objects.asMap().entries.map((entry) {
              final index = entry.key;
              final object = entry.value;
              return _buildObject(object, _getColorForObject(index));
            }),

            // Close button at top-right
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF56585C),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close Preview (or click anywhere / press ESC)',
                ),
              ),
            ),

            // Instructions at top-left
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF56585C),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Object Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Showing ${widget.objects.length} object(s)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hover over objects for details',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Hovered object info at bottom
            if (_hoveredObject != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF56585C),
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _hoveredObject!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hoveredObject!.isPoint
                              ? 'Point: (${_hoveredObject!.x}, ${_hoveredObject!.y})'
                              : 'Rectangle: (${_hoveredObject!.x}, ${_hoveredObject!.y}) to (${_hoveredObject!.x2}, ${_hoveredObject!.y2})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (_hoveredObject!.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _hoveredObject!.description!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObject(ScreenObject object, Color color) {
    if (object.isPoint) {
      return _buildPoint(object, color);
    } else {
      return _buildRectangle(object, color);
    }
  }

  Widget _buildPoint(ScreenObject object, Color color) {
    final isHovered = _hoveredObject?.id == object.id;

    return Positioned(
      left: object.x.toDouble() - 15,
      top: object.y.toDouble() - 15,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredObject = object),
        onExit: (_) => setState(() => _hoveredObject = null),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isHovered ? 0.8 : 0.5),
            border: Border.all(
              color: isHovered ? Colors.white : color,
              width: isHovered ? 3 : 2,
            ),
          ),
          child: Stack(
            children: [
              // Center dot
              Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Crosshair
              Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRectangle(ScreenObject object, Color color) {
    final isHovered = _hoveredObject?.id == object.id;

    // Calculate actual position and size
    final left = math.min(object.x, object.x2!).toDouble();
    final top = math.min(object.y, object.y2!).toDouble();
    final width = (object.x2! - object.x).abs().toDouble();
    final height = (object.y2! - object.y).abs().toDouble();

    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredObject = object),
        onExit: (_) => setState(() => _hoveredObject = null),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isHovered ? 0.3 : 0.15),
            border: Border.all(
              color: isHovered ? Colors.white : color,
              width: isHovered ? 4 : 3,
            ),
          ),
          child: Stack(
            children: [
              // Object name at top-left
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: color.withValues(alpha: 0.9),
                  child: Text(
                    object.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Corner markers
              _buildCornerMarker(true, true, color), // Top-left
              _buildCornerMarker(true, false, color), // Top-right
              _buildCornerMarker(false, true, color), // Bottom-left
              _buildCornerMarker(false, false, color), // Bottom-right
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerMarker(bool top, bool left, Color color) {
    return Positioned(
      top: top ? 0 : null,
      bottom: !top ? 0 : null,
      left: left ? 0 : null,
      right: !left ? 0 : null,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

