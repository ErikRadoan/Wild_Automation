import 'package:flutter/material.dart';

/// Overlay screen for coordinate picking and object preview
/// This screen shows a transparent canvas with opaque markers/crosshair
class OverlayScreen extends StatelessWidget {
  final OverlayMode mode;
  final List<OverlayObject>? objects;
  final int? firstPointX;
  final int? firstPointY;
  final Function(int x, int y)? onCoordinateSelected;
  final VoidCallback? onClose;

  const OverlayScreen({
    super.key,
    required this.mode,
    this.objects,
    this.firstPointX,
    this.firstPointY,
    this.onCoordinateSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == OverlayMode.coordinatePicker) {
      return _CoordinatePickerOverlay(
        onCoordinateSelected: onCoordinateSelected!,
        onClose: onClose!,
        firstPointX: firstPointX,
        firstPointY: firstPointY,
      );
    } else {
      return _ObjectPreviewOverlay(
        objects: objects!,
        onClose: onClose!,
      );
    }
  }
}

enum OverlayMode {
  coordinatePicker,
  objectPreview,
}

class OverlayObject {
  final String name;
  final bool isPoint;
  final int x;
  final int y;
  final int? x2;
  final int? y2;

  OverlayObject({
    required this.name,
    required this.isPoint,
    required this.x,
    required this.y,
    this.x2,
    this.y2,
  });
}

/// Coordinate picker overlay with transparent background and opaque crosshair
class _CoordinatePickerOverlay extends StatefulWidget {
  final Function(int x, int y) onCoordinateSelected;
  final VoidCallback onClose;
  final int? firstPointX;
  final int? firstPointY;

  const _CoordinatePickerOverlay({
    required this.onCoordinateSelected,
    required this.onClose,
    this.firstPointX,
    this.firstPointY,
  });

  @override
  State<_CoordinatePickerOverlay> createState() => _CoordinatePickerOverlayState();
}

class _CoordinatePickerOverlayState extends State<_CoordinatePickerOverlay> {
  int? _mouseX;
  int? _mouseY;
  double? _dpiScale;

  @override
  Widget build(BuildContext context) {
    // Get DPI scaling factor to convert logical pixels to physical pixels
    _dpiScale = MediaQuery.of(context).devicePixelRatio;

    // Get screen size for verification
    final logicalSize = MediaQuery.of(context).size;
    final physicalWidth = (logicalSize.width * _dpiScale!).toInt();
    final physicalHeight = (logicalSize.height * _dpiScale!).toInt();

    print('[CoordinatePicker] Device pixel ratio: $_dpiScale');
    print('[CoordinatePicker] Screen size (logical): ${logicalSize.width.toInt()}x${logicalSize.height.toInt()}');
    print('[CoordinatePicker] Screen size (physical): ${physicalWidth}x$physicalHeight');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Layer 1: Transparent background (click detection)
          Positioned.fill(
            child: MouseRegion(
              onHover: (event) {
                setState(() {
                  // Store logical coordinates for display
                  _mouseX = event.position.dx.toInt();
                  _mouseY = event.position.dy.toInt();
                });
              },
              child: GestureDetector(
                onTap: () {
                  if (_mouseX != null && _mouseY != null && _dpiScale != null) {
                    // Convert logical pixels to physical pixels before saving
                    final physicalX = (_mouseX! * _dpiScale!).toInt();
                    final physicalY = (_mouseY! * _dpiScale!).toInt();

                    print('[CoordinatePicker] Click detected:');
                    print('[CoordinatePicker]   Logical: ($_mouseX, $_mouseY)');
                    print('[CoordinatePicker]   Physical: ($physicalX, $physicalY)');
                    print('[CoordinatePicker]   DPI Scale: $_dpiScale');

                    widget.onCoordinateSelected(physicalX, physicalY);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Layer 2: Opaque UI elements
          // Instructions panel
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF56585C),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
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
                    if (_dpiScale != null)
                      Text(
                        'DPI Scale: ${(_dpiScale! * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFB5B7BB),
                          fontSize: 14,
                        ),
                      ),
                    if (_mouseX != null && _mouseY != null && _dpiScale != null)
                      Column(
                        children: [
                          Text(
                            'Screen Position: (${(_mouseX! * _dpiScale!).toInt()}, ${(_mouseY! * _dpiScale!).toInt()})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Display: ($_mouseX, $_mouseY)',
                            style: const TextStyle(
                              color: Color(0xFFB5B7BB),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onClose,
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

          // First point marker (when picking second point for rectangle)
          if (widget.firstPointX != null && widget.firstPointY != null && _dpiScale != null)
            Positioned(
              // Convert physical pixels back to logical pixels for display
              left: (widget.firstPointX! / _dpiScale!) - 20,
              top: (widget.firstPointY! / _dpiScale!) - 20,
              child: IgnorePointer(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    color: Colors.green.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Crosshair - Opaque and highly visible
          if (_mouseX != null && _mouseY != null)
            Positioned(
              left: _mouseX!.toDouble() - 20,
              top: _mouseY!.toDouble() - 20,
              child: IgnorePointer(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 3),
                    color: Colors.red.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.red, size: 24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Object preview overlay with transparent background and opaque red outlines
class _ObjectPreviewOverlay extends StatefulWidget {
  final List<OverlayObject> objects;
  final VoidCallback onClose;

  const _ObjectPreviewOverlay({
    required this.objects,
    required this.onClose,
  });

  @override
  State<_ObjectPreviewOverlay> createState() => _ObjectPreviewOverlayState();
}

class _ObjectPreviewOverlayState extends State<_ObjectPreviewOverlay> {
  OverlayObject? _hoveredObject;
  double? _dpiScale;

  @override
  Widget build(BuildContext context) {
    // Get DPI scaling factor
    _dpiScale = MediaQuery.of(context).devicePixelRatio;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Layer 1: Transparent background (click detection)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Layer 2: Opaque UI elements
          // Instructions panel
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF56585C),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Object Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.objects.length} object(s)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click anywhere to close',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Draw all objects with red outlines
          ...widget.objects.map((object) {
            final isHovered = _hoveredObject == object;

            if (object.isPoint) {
              return _buildPointMarker(object, isHovered);
            } else {
              return _buildRectangleMarker(object, isHovered);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPointMarker(OverlayObject object, bool isHovered) {
    if (_dpiScale == null) return const SizedBox.shrink();

    // Convert physical pixels to logical pixels for display
    final logicalX = object.x / _dpiScale!;
    final logicalY = object.y / _dpiScale!;

    return Positioned(
      left: logicalX - 20,
      top: logicalY - 20,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredObject = object),
        onExit: (_) => setState(() => _hoveredObject = null),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.3),
            border: Border.all(
              color: Colors.red,
              width: isHovered ? 4 : 3,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (isHovered)
                Positioned(
                  left: 45,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF56585C),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${object.name}\n(${object.x}, ${object.y})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildRectangleMarker(OverlayObject object, bool isHovered) {
    if (_dpiScale == null) return const SizedBox.shrink();

    // Convert physical pixels to logical pixels for display
    final logicalX1 = object.x / _dpiScale!;
    final logicalY1 = object.y / _dpiScale!;
    final logicalX2 = object.x2! / _dpiScale!;
    final logicalY2 = object.y2! / _dpiScale!;

    final width = (logicalX2 - logicalX1).abs().clamp(1.0, double.infinity);
    final height = (logicalY2 - logicalY1).abs().clamp(1.0, double.infinity);

    final left = logicalX1 < logicalX2 ? logicalX1 : logicalX2;
    final top = logicalY1 < logicalY2 ? logicalY1 : logicalY2;

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
            color: Colors.red.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.red,
              width: isHovered ? 5 : 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF56585C),
                    borderRadius: BorderRadius.circular(4),
                  ),
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
              if (isHovered)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF56585C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '(${object.x}, ${object.y}) to (${object.x2}, ${object.y2})\n${width.toInt()}×${height.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
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

