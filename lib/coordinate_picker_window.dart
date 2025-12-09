import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';

/// Entry point for coordinate picker window
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.isEmpty) return;

  final windowId = int.parse(args[1]); // args[0] is "multi_window", args[1] is ID
  final arguments = args.length > 2 ? jsonDecode(args[2]) : {};

  runApp(CoordinatePickerWindow(
    windowController: WindowController.fromWindowId(windowId),
    arguments: arguments,
  ));
}

class CoordinatePickerWindow extends StatelessWidget {
  final WindowController windowController;
  final Map<String, dynamic> arguments;

  const CoordinatePickerWindow({
    super.key,
    required this.windowController,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CoordinatePickerScreen(
        windowController: windowController,
        screenWidth: (arguments['screenWidth'] as num?)?.toDouble() ?? 1920.0,
        screenHeight: (arguments['screenHeight'] as num?)?.toDouble() ?? 1080.0,
      ),
    );
  }
}

class CoordinatePickerScreen extends StatefulWidget {
  final WindowController windowController;
  final double screenWidth;
  final double screenHeight;

  const CoordinatePickerScreen({
    super.key,
    required this.windowController,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<CoordinatePickerScreen> createState() => _CoordinatePickerScreenState();
}

class _CoordinatePickerScreenState extends State<CoordinatePickerScreen> {
  int? _mouseX;
  int? _mouseY;
  bool _isSetup = false;

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
      print('Error setting up coordinate picker window: $e');
      setState(() => _isSetup = true); // Continue anyway
    }
  }

  void _handleClick() async {
    if (_mouseX != null && _mouseY != null) {
      // Send coordinates back to main window
      await DesktopMultiWindow.invokeMethod(
        0,
        'coordinateSelected',
        {'x': _mouseX, 'y': _mouseY},
      );
      await widget.windowController.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.4), // 40% transparent gray
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mouseX = event.position.dx.toInt();
            _mouseY = event.position.dy.toInt();
          });
        },
        child: GestureDetector(
          onTap: _handleClick,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Container(color: Colors.transparent),

              // Instructions
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF56585C),
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
                          Text(
                            'Position: ($_mouseX, $_mouseY)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Press ESC to cancel',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Crosshair
              if (_mouseX != null && _mouseY != null)
                Positioned(
                  left: _mouseX!.toDouble() - 15,
                  top: _mouseY!.toDouble() - 15,
                  child: IgnorePointer(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
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

