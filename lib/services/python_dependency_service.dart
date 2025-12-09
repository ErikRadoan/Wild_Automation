import 'dart:io';
import 'package:process_run/process_run.dart';

/// Service for checking and installing Python dependencies
class PythonDependencyService {
  final Shell _shell = Shell();

  /// Required Python packages for WILD Automate
  static const Map<String, String> requiredPackages = {
    'pyautogui': '0.9.53',
    'pywin32': '305',
    'pillow': '9.0.0',
    'easyocr': '1.7.0',
  };

  /// Check if Python is installed
  Future<PythonCheckResult> checkPython() async {
    try {
      final result = await _shell.run('python --version');
      if (result.first.exitCode == 0) {
        final version = result.first.stdout.toString().trim();
        return PythonCheckResult(
          isInstalled: true,
          version: version,
          command: 'python',
        );
      }
    } catch (_) {}

    try {
      final result = await _shell.run('python3 --version');
      if (result.first.exitCode == 0) {
        final version = result.first.stdout.toString().trim();
        return PythonCheckResult(
          isInstalled: true,
          version: version,
          command: 'python3',
        );
      }
    } catch (_) {}

    return PythonCheckResult(isInstalled: false);
  }

  /// Check status of all required packages
  Future<Map<String, PackageStatus>> checkPackages(String pythonCommand) async {
    final statuses = <String, PackageStatus>{};

    for (final package in requiredPackages.keys) {
      try {
        final result = await _shell.run('$pythonCommand -m pip show $package');

        if (result.first.exitCode == 0) {
          final output = result.first.stdout.toString();
          final versionMatch = RegExp(r'Version:\s*(.+)').firstMatch(output);
          final version = versionMatch?.group(1)?.trim() ?? 'unknown';

          statuses[package] = PackageStatus(
            name: package,
            isInstalled: true,
            installedVersion: version,
            requiredVersion: requiredPackages[package]!,
          );
        } else {
          statuses[package] = PackageStatus(
            name: package,
            isInstalled: false,
            requiredVersion: requiredPackages[package]!,
          );
        }
      } catch (e) {
        statuses[package] = PackageStatus(
          name: package,
          isInstalled: false,
          requiredVersion: requiredPackages[package]!,
          error: e.toString(),
        );
      }
    }

    return statuses;
  }

  /// Install a single package
  Future<InstallResult> installPackage(
    String pythonCommand,
    String packageName,
    void Function(String)? onProgress,
  ) async {
    try {
      onProgress?.call('Installing $packageName...');

      final process = await Process.start(
        pythonCommand,
        ['-m', 'pip', 'install', packageName],
      );

      final stdout = StringBuffer();
      final stderr = StringBuffer();

      process.stdout.listen((data) {
        final text = String.fromCharCodes(data);
        stdout.write(text);
        onProgress?.call(text);
      });

      process.stderr.listen((data) {
        final text = String.fromCharCodes(data);
        stderr.write(text);
        onProgress?.call(text);
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        return InstallResult(
          success: true,
          packageName: packageName,
          message: 'Successfully installed $packageName',
        );
      } else {
        return InstallResult(
          success: false,
          packageName: packageName,
          message: 'Failed to install $packageName',
          error: stderr.toString(),
        );
      }
    } catch (e) {
      return InstallResult(
        success: false,
        packageName: packageName,
        message: 'Error installing $packageName',
        error: e.toString(),
      );
    }
  }

  /// Install all missing packages
  Future<List<InstallResult>> installMissingPackages(
    String pythonCommand,
    Map<String, PackageStatus> packageStatuses,
    void Function(String)? onProgress,
  ) async {
    final results = <InstallResult>[];

    final missingPackages = packageStatuses.entries
        .where((e) => !e.value.isInstalled)
        .map((e) => e.key)
        .toList();

    for (final package in missingPackages) {
      final result = await installPackage(pythonCommand, package, onProgress);
      results.add(result);
    }

    return results;
  }

  /// Check if EasyOCR is installed
  Future<bool> checkEasyOCR() async {
    try {
      final result = await _shell.run('python -c "import easyocr"');
      return result.first.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

/// Result of Python installation check
class PythonCheckResult {
  final bool isInstalled;
  final String? version;
  final String? command;

  const PythonCheckResult({
    required this.isInstalled,
    this.version,
    this.command,
  });
}

/// Status of a Python package
class PackageStatus {
  final String name;
  final bool isInstalled;
  final String? installedVersion;
  final String requiredVersion;
  final String? error;

  const PackageStatus({
    required this.name,
    required this.isInstalled,
    this.installedVersion,
    required this.requiredVersion,
    this.error,
  });

  bool get isUpToDate {
    if (!isInstalled || installedVersion == null) return false;
    // Simple version comparison (would need proper semantic versioning in production)
    return true; // For now, just check if installed
  }
}

/// Result of package installation
class InstallResult {
  final bool success;
  final String packageName;
  final String message;
  final String? error;

  const InstallResult({
    required this.success,
    required this.packageName,
    required this.message,
    this.error,
  });
}

