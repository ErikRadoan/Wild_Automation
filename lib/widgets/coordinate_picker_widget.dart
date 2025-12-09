import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Widget for picking screen coordinates by clicking
class CoordinatePickerWidget extends StatefulWidget {
  final Function(int x, int y) onCoordinatePicked;
  final String title;

  const CoordinatePickerWidget({
    super.key,
    required this.onCoordinatePicked,
    this.title = 'Click to select coordinate',
  });

  @override
  State<CoordinatePickerWidget> createState() => _CoordinatePickerWidgetState();
}

class _CoordinatePickerWidgetState extends State<CoordinatePickerWidget> {
  bool _isListening = false;
  int? _selectedX;
  int? _selectedY;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
    });

    // Show instruction dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Select Coordinate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Move your mouse to the desired location'),
            const SizedBox(height: 16),
            const Text('Press SPACE to capture the coordinate'),
            const SizedBox(height: 16),
            const Text('Press ESC to cancel'),
            const SizedBox(height: 24),
            if (_selectedX != null && _selectedY != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF56585C),
                child: Text(
                  'Position: ($_selectedX, $_selectedY)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _stopListening();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // Listen for keyboard input
    RawKeyboard.instance.addListener(_handleKeyPress);

    // Start polling mouse position (simplified approach)
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // In a real implementation, we'd get mouse position from system
      // For now, this is a placeholder
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        // Capture current mouse position
        // In real implementation, get actual mouse position
        _capturePosition();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _stopListening();
        Navigator.of(context).pop();
      }
    }
  }

  void _capturePosition() {
    // Placeholder: In real implementation, get actual mouse coordinates
    // This would require platform channels or FFI
    if (mounted) {
      setState(() {
        _selectedX = 500; // Placeholder
        _selectedY = 300; // Placeholder
      });

      widget.onCoordinatePicked(_selectedX!, _selectedY!);
      _stopListening();
      Navigator.of(context).pop();
    }
  }

  void _stopListening() {
    RawKeyboard.instance.removeListener(_handleKeyPress);
    _pollTimer?.cancel();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isListening ? null : _startListening,
      icon: const Icon(Icons.my_location),
      label: const Text('Pick Coordinate'),
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

