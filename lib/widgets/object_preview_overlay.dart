import 'package:flutter/material.dart';
import '../models/screen_object.dart';
import 'dart:async';

/// Overlay that shows live preview of screen objects
class ObjectPreviewOverlay extends StatefulWidget {
  final List<ScreenObject> objects;
  final Function(ScreenObject)? onObjectSelected;
  final VoidCallback onClose;

  const ObjectPreviewOverlay({
    super.key,
    required this.objects,
    this.onObjectSelected,
    required this.onClose,
  });

  @override
  State<ObjectPreviewOverlay> createState() => _ObjectPreviewOverlayState();
}

class _ObjectPreviewOverlayState extends State<ObjectPreviewOverlay> {
  ScreenObject? _hoveredObject;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update overlay periodically
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        children: [
          // Close button
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF56585C),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
                tooltip: 'Close Preview',
              ),
            ),
          ),

          // Instructions
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
                    'Object Preview Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${widget.objects.length} object(s)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click on an object to select it',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Draw objects
          ...widget.objects.map((obj) => _buildObjectOverlay(obj)),

          // Object info on hover
          if (_hoveredObject != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF56585C),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hoveredObject!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hoveredObject!.isPoint
                          ? 'Point: (${_hoveredObject!.x}, ${_hoveredObject!.y})'
                          : 'Rectangle: (${_hoveredObject!.x}, ${_hoveredObject!.y}, ${_hoveredObject!.width}, ${_hoveredObject!.height})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (_hoveredObject!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _hoveredObject!.description!,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildObjectOverlay(ScreenObject object) {
    // Note: These positions are relative to the overlay, not screen
    // In a real implementation, you'd need to map actual screen coordinates

    final isHovered = _hoveredObject?.id == object.id;
    final color = object.isPoint
        ? const Color(0xFFB5B7BB)
        : const Color(0xFF56585C);

    if (object.isPoint) {
      return Positioned(
        left: object.x.toDouble() - 10,
        top: object.y.toDouble() - 10,
        child: GestureDetector(
          onTap: () => widget.onObjectSelected?.call(object),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredObject = object),
            onExit: (_) => setState(() => _hoveredObject = null),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                border: Border.all(
                  color: isHovered ? Colors.white : color,
                  width: isHovered ? 3 : 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Positioned(
        left: object.x.toDouble(),
        top: object.y.toDouble(),
        child: GestureDetector(
          onTap: () => widget.onObjectSelected?.call(object),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredObject = object),
            onExit: (_) => setState(() => _hoveredObject = null),
            child: Container(
              width: object.width.toDouble(),
              height: object.height.toDouble(),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                border: Border.all(
                  color: isHovered ? Colors.white : color,
                  width: isHovered ? 3 : 2,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: color.withValues(alpha: 0.8),
                  child: Text(
                    object.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

