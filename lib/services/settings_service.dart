import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'python_dependency_service.dart';

/// Service for managing app settings (theme, language, etc.)
class SettingsService extends ChangeNotifier {
  static const String _boxName = 'settings';
  late Box _box;
  final PythonDependencyService _depService = PythonDependencyService();

  ThemeMode _themeMode = ThemeMode.dark;
  String _languageCode = 'en';
  bool _hasMissingDependencies = false;
  bool _isCheckingDependencies = false;

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  bool get hasMissingDependencies => _hasMissingDependencies;
  bool get isCheckingDependencies => _isCheckingDependencies;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    _loadSettings();
    // Check dependencies on startup
    await checkDependencies();
  }

  void _loadSettings() {
    final theme = _box.get('theme', defaultValue: 'dark');
    _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;

    _languageCode = _box.get('language', defaultValue: 'en');
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _box.put('theme', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    await _box.put('language', code);
    notifyListeners();
  }

  Future<void> checkDependencies() async {
    _isCheckingDependencies = true;
    notifyListeners();

    try {
      // Check Python
      final pythonStatus = await _depService.checkPython();

      if (!pythonStatus.isInstalled) {
        _hasMissingDependencies = true;
      } else {
        // Check packages
        final packageStatuses = await _depService.checkPackages(pythonStatus.command!);

        // Check if any packages are missing
        _hasMissingDependencies = false;
        for (var status in packageStatuses.values) {
          if (!status.isInstalled) {
            _hasMissingDependencies = true;
            break;
          }
        }
      }
    } catch (e) {
      _hasMissingDependencies = true;
    } finally {
      _isCheckingDependencies = false;
      notifyListeners();
    }
  }
}

