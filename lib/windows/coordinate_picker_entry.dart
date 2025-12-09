// Entry point for coordinate picker sub-window
// This file is used as the entry point for the coordinate picker window
// DO NOT import main.dart or window_manager here!

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.isEmpty) return;

  final windowId = int.parse(args[0]);
  final arguments = args.length > 1 ? jsonDecode(args[1]) : {};

  runApp(CoordinatePickerApp(
    windowController: WindowController.fromWindowId(windowId),
    arguments: arguments,
  ));
}

class CoordinatePickerApp extends StatelessWidget {
  final WindowController windowController;
  final Map<String, dynamic> arguments;

  const CoordinatePickerApp({
    super.key,
    required this.windowController,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CoordinatePickerScreen(windowController: windowController),
    );
  }
}

class CoordinatePickerScreen extends StatefulWidget {
  final WindowController windowController;

  const CoordinatePickerScreen({super.key, required this.windowController});

  @override
  State<CoordinatePickerScreen> createState() => _CoordinatePickerScreenState();
}

class _CoordinatePickerScreenState extends State<CoordinatePickerScreen> {
  int? _mouseX;
  int? _mouseY;

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
      backgroundColor: Colors.black.withOpacity(0.4),
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

