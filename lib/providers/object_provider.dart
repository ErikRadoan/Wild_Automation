import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/screen_object.dart';
import '../services/storage_service.dart';

/// Provider for managing screen objects
class ObjectProvider extends ChangeNotifier {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  List<ScreenObject> _objects = [];
  bool _isLoading = false;
  String? _error;

  ObjectProvider(this._storage) {
    _loadObjects();
  }

  List<ScreenObject> get objects => List.unmodifiable(_objects);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadObjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _objects = _storage.getAllScreenObjects();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPoint({
    required String name,
    required int x,
    required int y,
    String? description,
  }) async {
    try {
      final object = ScreenObject.point(
        id: _uuid.v4(),
        name: name,
        x: x,
        y: y,
        description: description,
      );

      await _storage.saveScreenObject(object);
      _objects.add(object);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createRectangle({
    required String name,
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    String? description,
  }) async {
    try {
      final object = ScreenObject.rectangle(
        id: _uuid.v4(),
        name: name,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        description: description,
      );

      await _storage.saveScreenObject(object);
      _objects.add(object);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateObject(ScreenObject object) async {
    try {
      await _storage.saveScreenObject(object);
      final index = _objects.indexWhere((o) => o.id == object.id);
      if (index != -1) {
        _objects[index] = object;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteObject(String id) async {
    try {
      await _storage.deleteScreenObject(id);
      _objects.removeWhere((o) => o.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void refresh() {
    _loadObjects();
  }
}

