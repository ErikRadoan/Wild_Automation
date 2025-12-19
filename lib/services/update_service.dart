import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Service for checking and managing app updates
class UpdateService extends ChangeNotifier {
  static const String githubOwner = 'ErikRadoan';
  static const String githubRepo = 'Wild_Automation';
  static const String currentVersion = '1.7.2'; // Update this with each release
  static const int currentBuildNumber = 22; // Update this with each release

  bool _isChecking = false;
  bool _updateAvailable = false;
  String? _latestVersion;
  String? _downloadUrl;
  String? _releaseNotes;
  String? _error;

  bool get isChecking => _isChecking;
  bool get updateAvailable => _updateAvailable;
  String? get latestVersion => _latestVersion;
  String? get downloadUrl => _downloadUrl;
  String? get releaseNotes => _releaseNotes;
  String? get error => _error;

  /// Check for updates from GitHub releases
  Future<void> checkForUpdates() async {
    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String;
        _latestVersion = tagName.replaceFirst('v', ''); // Remove 'v' prefix
        _releaseNotes = data['body'] as String?;

        // Parse version number (e.g., "1.6.0+14")
        final versionParts = _latestVersion!.split('+');
        final latestVersionNumber = versionParts[0];
        final latestBuildNumber = versionParts.length > 1
            ? int.tryParse(versionParts[1]) ?? 0
            : 0;

        // Compare versions
        _updateAvailable = _compareVersions(
          latestVersionNumber,
          latestBuildNumber,
          currentVersion,
          currentBuildNumber,
        );

        if (_updateAvailable) {
          // Find the Windows release asset
          final assets = data['assets'] as List<dynamic>;
          for (var asset in assets) {
            final name = asset['name'] as String;
            if (name.contains('WILD_Automate') && name.endsWith('.zip')) {
              _downloadUrl = asset['browser_download_url'] as String;
              break;
            }
          }
        }
      } else if (response.statusCode == 404) {
        _error = 'No releases found';
      } else {
        _error = 'Failed to check for updates: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error checking for updates: $e';
      debugPrint('Update check error: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Compare two version numbers
  /// Returns true if latest version is newer
  bool _compareVersions(
    String latestVersion,
    int latestBuild,
    String currentVersion,
    int currentBuild,
  ) {
    final latestParts = latestVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    // Compare major.minor.patch
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    // If version numbers are equal, compare build numbers
    return latestBuild > currentBuild;
  }

  /// Start the update process by launching the updater
  Future<bool> startUpdate() async {
    if (!_updateAvailable || _downloadUrl == null) {
      return false;
    }

    try {
      // Get paths
      final currentExe = Platform.resolvedExecutable;
      final currentDir = path.dirname(currentExe);
      final updaterPath = path.join(currentDir, 'updater.exe');

      // Check if updater exists
      if (!await File(updaterPath).exists()) {
        _error = 'Updater not found. Please reinstall the application.';
        notifyListeners();
        return false;
      }

      // Launch updater with arguments:
      // 1. Download URL
      // 2. Current executable path
      // 3. Process ID (to wait for main app to close)
      await Process.start(
        updaterPath,
        [
          _downloadUrl!,
          currentExe,
          pid.toString(),
        ],
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      _error = 'Failed to start updater: $e';
      debugPrint('Update start error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Reset update state
  void reset() {
    _updateAvailable = false;
    _latestVersion = null;
    _downloadUrl = null;
    _releaseNotes = null;
    _error = null;
    notifyListeners();
  }
}

