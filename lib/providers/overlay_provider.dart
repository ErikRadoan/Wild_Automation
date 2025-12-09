import 'package:flutter/material.dart';
import '../screens/overlay_screen.dart';

/// Provider for managing overlay mode state
class OverlayProvider extends ChangeNotifier {
  OverlayMode? _mode;
  List<OverlayObject>? _objects;
  Function(int x, int y)? _onCoordinateSelected;
  int? _firstPointX;
  int? _firstPointY;

  bool get isInOverlayMode => _mode != null;
  OverlayMode? get mode => _mode;
  List<OverlayObject>? get objects => _objects;
  Function(int x, int y)? get onCoordinateSelected => _onCoordinateSelected;
  int? get firstPointX => _firstPointX;
  int? get firstPointY => _firstPointY;

  void enterCoordinatePickerMode(Function(int x, int y) onSelected) {
    _mode = OverlayMode.coordinatePicker;
    _onCoordinateSelected = onSelected;
    _firstPointX = null;
    _firstPointY = null;
    notifyListeners();
  }

  void enterCoordinatePickerModeWithFirstPoint(int x1, int y1, Function(int x, int y) onSelected) {
    _mode = OverlayMode.coordinatePicker;
    _onCoordinateSelected = onSelected;
    _firstPointX = x1;
    _firstPointY = y1;
    notifyListeners();
  }

  void enterObjectPreviewMode(List<OverlayObject> objects) {
    _mode = OverlayMode.objectPreview;
    _objects = objects;
    notifyListeners();
  }

  void exitOverlayMode() {
    _mode = null;
    _objects = null;
    _onCoordinateSelected = null;
    _firstPointX = null;
    _firstPointY = null;
    notifyListeners();
  }

  void handleCoordinateSelected(int x, int y) {
    if (_onCoordinateSelected != null) {
      _onCoordinateSelected!(x, y);
    }
    exitOverlayMode();
  }
}

