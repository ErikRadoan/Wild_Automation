import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/screen_object.dart';
import '../models/window_target.dart';
import '../models/flow.dart';
import '../models/project.dart';

/// Service for storing and retrieving data using Hive
class StorageService {
  static const String _objectsBoxName = 'screen_objects';
  static const String _windowsBoxName = 'window_targets';
  static const String _flowsBoxName = 'flows';
  static const String _projectsBoxName = 'projects';
  static const String _settingsBoxName = 'settings';

  Box<ScreenObject>? _objectsBox;
  Box<WindowTarget>? _windowsBox;
  Box<Flow>? _flowsBox;
  Box<Project>? _projectsBox;
  Box<dynamic>? _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    // Get the application support directory for proper data storage
    final appDir = await getApplicationSupportDirectory();
    final hivePath = '${appDir.path}/hive_data';

    // Initialize Hive with the proper directory
    await Hive.initFlutter(hivePath);

    // Register adapters (will be generated)
    Hive.registerAdapter(ScreenObjectAdapter());
    Hive.registerAdapter(ScreenObjectTypeAdapter());
    Hive.registerAdapter(WindowTargetAdapter());
    Hive.registerAdapter(WindowMatchTypeAdapter());
    Hive.registerAdapter(FlowAdapter());
    Hive.registerAdapter(ProjectAdapter());

    // Open boxes
    _objectsBox = await Hive.openBox<ScreenObject>(_objectsBoxName);
    _windowsBox = await Hive.openBox<WindowTarget>(_windowsBoxName);
    _flowsBox = await Hive.openBox<Flow>(_flowsBoxName);
    _projectsBox = await Hive.openBox<Project>(_projectsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // Screen Objects

  Future<void> saveScreenObject(ScreenObject object) async {
    await _objectsBox!.put(object.id, object);
  }

  Future<void> deleteScreenObject(String id) async {
    await _objectsBox!.delete(id);
  }

  ScreenObject? getScreenObject(String id) {
    return _objectsBox!.get(id);
  }

  List<ScreenObject> getAllScreenObjects() {
    return _objectsBox!.values.toList();
  }

  Stream<BoxEvent> watchScreenObjects() {
    return _objectsBox!.watch();
  }

  // Window Targets

  Future<void> saveWindowTarget(WindowTarget target) async {
    await _windowsBox!.put(target.id, target);
  }

  Future<void> deleteWindowTarget(String id) async {
    await _windowsBox!.delete(id);
  }

  WindowTarget? getWindowTarget(String id) {
    return _windowsBox!.get(id);
  }

  List<WindowTarget> getAllWindowTargets() {
    return _windowsBox!.values.toList();
  }

  Stream<BoxEvent> watchWindowTargets() {
    return _windowsBox!.watch();
  }

  // Flows

  Future<void> saveFlow(Flow flow) async {
    await _flowsBox!.put(flow.id, flow);
  }

  Future<void> deleteFlow(String id) async {
    await _flowsBox!.delete(id);
  }

  Flow? getFlow(String id) {
    return _flowsBox!.get(id);
  }

  List<Flow> getAllFlows() {
    return _flowsBox!.values.toList();
  }

  Stream<BoxEvent> watchFlows() {
    return _flowsBox!.watch();
  }

  // Settings

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox!.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox!.delete(key);
  }

  // Projects

  Future<void> saveProject(Project project) async {
    await _projectsBox!.put(project.id, project);
  }

  Future<void> deleteProject(String id) async {
    await _projectsBox!.delete(id);
  }

  Project? getProject(String id) {
    return _projectsBox!.get(id);
  }

  List<Project> getAllProjects() {
    return _projectsBox!.values.toList();
  }

  Stream<BoxEvent> watchProjects() {
    return _projectsBox!.watch();
  }

  // Cleanup

  Future<void> dispose() async {
    await _objectsBox?.close();
    await _windowsBox?.close();
    await _flowsBox?.close();
    await _projectsBox?.close();
    await _settingsBox?.close();
  }

  Future<void> clearAll() async {
    await _objectsBox?.clear();
    await _windowsBox?.clear();
    await _flowsBox?.clear();
  }
}

