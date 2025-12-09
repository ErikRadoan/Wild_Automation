import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/object_provider.dart';
import '../providers/overlay_provider.dart';
import '../models/screen_object.dart';
import 'dart:async';

/// Dialog for creating/editing screen objects
class ObjectFormDialog extends StatefulWidget {
  final ScreenObject? object;

  const ObjectFormDialog({super.key, this.object});

  @override
  State<ObjectFormDialog> createState() => _ObjectFormDialogState();
}

class _ObjectFormDialogState extends State<ObjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _xController;
  late TextEditingController _yController;
  late TextEditingController _x2Controller;
  late TextEditingController _y2Controller;
  late TextEditingController _descriptionController;
  late bool _isPoint;

  // Static cache to preserve state during coordinate picking
  static Map<String, String>? _stateCache;

  @override
  void initState() {
    super.initState();


    // Restore from cache if available, otherwise use widget data
    if (_stateCache != null) {
      _isPoint = _stateCache!['isPoint'] == 'true';
      _nameController = TextEditingController(text: _stateCache!['name'] ?? '');
      _xController = TextEditingController(text: _stateCache!['x'] ?? '0');
      _yController = TextEditingController(text: _stateCache!['y'] ?? '0');
      _x2Controller = TextEditingController(text: _stateCache!['x2'] ?? '0');
      _y2Controller = TextEditingController(text: _stateCache!['y2'] ?? '0');
      _descriptionController = TextEditingController(text: _stateCache!['description'] ?? '');
      _stateCache = null; // Clear cache after restoring
    } else {
      _isPoint = widget.object?.isPoint ?? true;
      _nameController = TextEditingController(text: widget.object?.name ?? '');
      _xController = TextEditingController(text: widget.object?.x.toString() ?? '0');
      _yController = TextEditingController(text: widget.object?.y.toString() ?? '0');
      _x2Controller = TextEditingController(text: widget.object?.x2?.toString() ?? '0');
      _y2Controller = TextEditingController(text: widget.object?.y2?.toString() ?? '0');
      _descriptionController = TextEditingController(text: widget.object?.description ?? '');
    }
  }

  void _saveStateToCache() {
    _stateCache = {
      'isPoint': _isPoint.toString(),
      'name': _nameController.text,
      'x': _xController.text,
      'y': _yController.text,
      'x2': _x2Controller.text,
      'y2': _y2Controller.text,
      'description': _descriptionController.text,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _xController.dispose();
    _yController.dispose();
    _x2Controller.dispose();
    _y2Controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(widget.object == null ? 'New Screen Object' : 'Edit Screen Object'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Object type selector
                if (widget.object == null)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Point'),
                        icon: Icon(Icons.my_location),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Rectangle'),
                        icon: Icon(Icons.crop_square),
                      ),
                    ],
                    selected: {_isPoint},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _isPoint = selected.first;
                      });
                    },
                  ),
                const SizedBox(height: 16),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., LoginButton',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
                      return 'Name must be a valid identifier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // First coordinate picker (for Point or Rectangle corner 1)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFB5B7BB)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPoint ? 'Point Coordinate' : 'Top-Left Corner (x1, y1)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF56585C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _pickFirstCoordinate(),
                        icon: const Icon(Icons.mouse),
                        label: const Text('Click to Select Position'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _xController,
                              decoration: const InputDecoration(
                                labelText: 'X *',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _yController,
                              decoration: const InputDecoration(
                                labelText: 'Y *',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Second coordinate picker (for Rectangle corner 2)
                if (!_isPoint) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFB5B7BB)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bottom-Right Corner (x2, y2)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF56585C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _pickSecondCoordinate(),
                          icon: const Icon(Icons.mouse),
                          label: const Text('Click to Select Position'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _x2Controller,
                                decoration: const InputDecoration(
                                  labelText: 'X2 *',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _y2Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Y2 *',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.object == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _pickFirstCoordinate() async {
    // Save current state
    _saveStateToCache();

    // Get provider reference BEFORE closing dialog
    final overlayProvider = context.read<OverlayProvider>();

    // Get the root context (scaffold/screen context) before closing
    BuildContext? rootContext;
    context.visitAncestorElements((element) {
      if (element.widget is Navigator) {
        rootContext = element;
        return false; // Stop traversing
      }
      return true; // Continue traversing
    });

    final completer = Completer<CoordinatePoint?>();

    // Close the dialog first
    if (!mounted) return;
    Navigator.of(context).pop();

    // Wait a bit for dialog to close
    await Future.delayed(const Duration(milliseconds: 300));

    // Enter coordinate picker mode using the provider reference
    overlayProvider.enterCoordinatePickerMode((x, y) {
      completer.complete(CoordinatePoint(x, y));
    });

    // Wait for coordinate selection
    final point = await completer.future;

    if (point != null) {
      // Update the cache with new coordinates
      _stateCache!['x'] = point.x.toString();
      _stateCache!['y'] = point.y.toString();
    }

    // Re-open the dialog with updated values
    await Future.delayed(const Duration(milliseconds: 100));

    final ctx = rootContext;
    if (ctx != null && ctx.mounted) {
      showDialog(
        context: ctx,
        builder: (context) => ObjectFormDialog(object: widget.object),
      );
    }
  }

  Future<void> _pickSecondCoordinate() async {
    // Get first coordinate from text fields
    final x1 = int.tryParse(_xController.text) ?? 0;
    final y1 = int.tryParse(_yController.text) ?? 0;

    // Save current state
    _saveStateToCache();

    // Get provider reference BEFORE closing dialog
    final overlayProvider = context.read<OverlayProvider>();

    // Get the root context (scaffold/screen context) before closing
    BuildContext? rootContext;
    context.visitAncestorElements((element) {
      if (element.widget is Navigator) {
        rootContext = element;
        return false; // Stop traversing
      }
      return true; // Continue traversing
    });

    final completer = Completer<CoordinatePoint?>();

    // Close the dialog first
    if (!mounted) return;
    Navigator.of(context).pop();

    // Wait a bit for dialog to close
    await Future.delayed(const Duration(milliseconds: 300));

    // Enter coordinate picker mode with first point for visualization
    overlayProvider.enterCoordinatePickerModeWithFirstPoint(
      x1,
      y1,
      (x, y) {
        completer.complete(CoordinatePoint(x, y));
      },
    );

    // Wait for coordinate selection
    final point = await completer.future;

    if (point != null) {
      // Update the cache with new coordinates
      _stateCache!['x2'] = point.x.toString();
      _stateCache!['y2'] = point.y.toString();
    }

    // Re-open the dialog with updated values
    await Future.delayed(const Duration(milliseconds: 100));

    final ctx = rootContext;
    if (ctx != null && ctx.mounted) {
      showDialog(
        context: ctx,
        builder: (context) => ObjectFormDialog(object: widget.object),
      );
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ObjectProvider>();
    final name = _nameController.text;
    final x = int.parse(_xController.text);
    final y = int.parse(_yController.text);
    final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;

    try {
      if (widget.object == null) {
        // Create new object
        if (_isPoint) {
          await provider.createPoint(
            name: name,
            x: x,
            y: y,
            description: description,
          );
        } else {
          final x2 = int.parse(_x2Controller.text);
          final y2 = int.parse(_y2Controller.text);
          await provider.createRectangle(
            name: name,
            x1: x,
            y1: y,
            x2: x2,
            y2: y2,
            description: description,
          );
        }
      } else {
        // Update existing object
        final updated = widget.object!.copyWith(
          name: name,
          x: x,
          y: y,
          x2: _isPoint ? null : int.parse(_x2Controller.text),
          y2: _isPoint ? null : int.parse(_y2Controller.text),
          description: description,
        );
        await provider.updateObject(updated);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Simple coordinate point class
class CoordinatePoint {
  final int x;
  final int y;

  CoordinatePoint(this.x, this.y);
}

