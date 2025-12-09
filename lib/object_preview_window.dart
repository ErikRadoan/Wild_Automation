import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Entry point for object preview window
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.isEmpty) return;

  final windowId = int.parse(args[1]); // args[0] is "multi_window", args[1] is ID
  final arguments = args.length > 2 ? jsonDecode(args[2]) : {};

  runApp(ObjectPreviewWindow(
    windowController: WindowController.fromWindowId(windowId),
    arguments: arguments,
  ));
}

class ObjectPreviewWindow extends StatelessWidget {
  final WindowController windowController;
  final Map<String, dynamic> arguments;

  const ObjectPreviewWindow({
    super.key,
    required this.windowController,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ObjectPreviewScreen(
        windowController: windowController,
        objects: (arguments['objects'] as List?)
            ?.map((e) => ScreenObjectData.fromJson(e))
            .toList() ?? [],
        screenWidth: (arguments['screenWidth'] as num?)?.toDouble() ?? 1920.0,
        screenHeight: (arguments['screenHeight'] as num?)?.toDouble() ?? 1080.0,
      ),
    );
  }
}

class ObjectPreviewScreen extends StatefulWidget {
  final WindowController windowController;
  final List<ScreenObjectData> objects;
  final double screenWidth;
  final double screenHeight;

  const ObjectPreviewScreen({
    super.key,
    required this.windowController,
    required this.objects,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<ObjectPreviewScreen> createState() => _ObjectPreviewScreenState();
}

class _ObjectPreviewScreenState extends State<ObjectPreviewScreen> {
  ScreenObjectData? _hoveredObject;
  bool _isSetup = false;

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
    _setupWindow();
  }

  Future<void> _setupWindow() async {
    try {
      // Set window to fullscreen and cover entire screen using passed dimensions
      await widget.windowController.setFrame(
        Rect.fromLTWH(0, 0, widget.screenWidth, widget.screenHeight),
      );

      setState(() => _isSetup = true);
    } catch (e) {
      print('Error setting up object preview window: $e');
      setState(() => _isSetup = true); // Continue anyway
    }
  }

  Color _getColorForObject(int index) {
    return _colors[index % _colors.length];
  }

  void _close() async {
    await widget.windowController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.4),
      body: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Container(color: Colors.transparent),

            // Draw all objects
            ...widget.objects.asMap().entries.map((entry) {
              final index = entry.key;
              final object = entry.value;
              return _buildObject(object, _getColorForObject(index));
            }),

            // Close button
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF56585C)),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: _close,
                  tooltip: 'Close (or click anywhere)',
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
                  ],
                ),
              ),
            ),

            // Hovered object info
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

  Widget _buildObject(ScreenObjectData object, Color color) {
    if (object.isPoint) {
      return _buildPoint(object, color);
    } else {
      return _buildRectangle(object, color);
    }
  }

  Widget _buildPoint(ScreenObjectData object, Color color) {
    final isHovered = _hoveredObject?.name == object.name;

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
              Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRectangle(ScreenObjectData object, Color color) {
    final isHovered = _hoveredObject?.name == object.name;

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
            ],
          ),
        ),
      ),
    );
  }
}

// Simple data class for passing object data
class ScreenObjectData {
  final String name;
  final bool isPoint;
  final int x;
  final int y;
  final int? x2;
  final int? y2;

  ScreenObjectData({
    required this.name,
    required this.isPoint,
    required this.x,
    required this.y,
    this.x2,
    this.y2,
  });

  factory ScreenObjectData.fromJson(Map<String, dynamic> json) {
    return ScreenObjectData(
      name: json['name'],
      isPoint: json['isPoint'],
      x: json['x'],
      y: json['y'],
      x2: json['x2'],
      y2: json['y2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isPoint': isPoint,
      'x': x,
      'y': y,
      'x2': x2,
      'y2': y2,
    };
  }
}

