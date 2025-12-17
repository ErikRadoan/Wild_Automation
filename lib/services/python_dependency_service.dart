import 'dart:io';
import 'package:process_run/process_run.dart';

/// Service for checking and installing Python dependencies
class PythonDependencyService {
  final Shell _shell = Shell();

  /// Short path for virtual environment to avoid Windows MAX_PATH issues
  static String get venvPath => 'C:\\wild_venv';

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

  /// Check if virtual environment exists and is configured
  Future<bool> checkVirtualEnvironment() async {
    final venvDir = Directory(venvPath);
    if (!await venvDir.exists()) {
      return false;
    }

    final pythonExe = File('$venvPath\\Scripts\\python.exe');
    return await pythonExe.exists();
  }

  /// Create virtual environment at short path
  Future<CreateVenvResult> createVirtualEnvironment(
    String pythonCommand,
    void Function(String)? onProgress,
  ) async {
    try {
      onProgress?.call('Creating virtual environment at $venvPath...');

      // Create venv directory if it doesn't exist
      final venvDir = Directory(venvPath);
      if (await venvDir.exists()) {
        onProgress?.call('Removing existing virtual environment...');
        await venvDir.delete(recursive: true);
      }

      // Create new virtual environment
      final process = await Process.start(
        pythonCommand,
        ['-m', 'venv', venvPath, '--clear'],
      );

      final stdout = StringBuffer();
      final stderr = StringBuffer();

      process.stdout.listen((data) {
        final text = String.fromCharCodes(data);
        stdout.write(text);
        onProgress?.call(text.trim());
      });

      process.stderr.listen((data) {
        final text = String.fromCharCodes(data);
        stderr.write(text);
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        onProgress?.call('Virtual environment created successfully!');
        return CreateVenvResult(success: true);
      } else {
        return CreateVenvResult(
          success: false,
          error: 'Failed to create virtual environment: ${stderr.toString()}',
        );
      }
    } catch (e) {
      return CreateVenvResult(
        success: false,
        error: 'Error creating virtual environment: $e',
      );
    }
  }

  /// Get the Python command for the virtual environment
  String getVenvPythonCommand() {
    return '$venvPath\\Scripts\\python.exe';
  }

  /// Check status of all required packages (checks both venv and global installation)
  Future<Map<String, PackageStatus>> checkPackages(String pythonCommand) async {
    final statuses = <String, PackageStatus>{};

    // Check if venv exists
    final venvExists = await checkVirtualEnvironment();
    final venvPython = venvExists ? getVenvPythonCommand() : null;

    for (final package in requiredPackages.keys) {
      bool isInstalled = false;
      String? installedVersion;
      String? error;

      // First, try to check in venv (if it exists)
      if (venvPython != null) {
        try {
          final result = await _shell.run('$venvPython -m pip show $package');
          if (result.first.exitCode == 0) {
            final output = result.first.stdout.toString();
            final versionMatch = RegExp(r'Version:\s*(.+)').firstMatch(output);
            installedVersion = versionMatch?.group(1)?.trim() ?? 'unknown';
            isInstalled = true;
          }
        } catch (e) {
          // Continue to check globally
        }
      }

      // If not found in venv (or venv doesn't exist), check globally
      if (!isInstalled) {
        try {
          final result = await _shell.run('$pythonCommand -m pip show $package');
          if (result.first.exitCode == 0) {
            final output = result.first.stdout.toString();
            final versionMatch = RegExp(r'Version:\s*(.+)').firstMatch(output);
            installedVersion = versionMatch?.group(1)?.trim() ?? 'unknown';
            isInstalled = true;
          }
        } catch (e) {
          error = e.toString();
        }
      }

      statuses[package] = PackageStatus(
        name: package,
        isInstalled: isInstalled,
        installedVersion: installedVersion,
        requiredVersion: requiredPackages[package]!,
        error: error,
      );
    }

    return statuses;
  }

  /// Install a single package with long path workarounds
  Future<InstallResult> installPackage(
    String pythonCommand,
    String packageName,
    void Function(String)? onProgress,
  ) async {
    try {
      // Ensure we're using venv Python
      final venvExists = await checkVirtualEnvironment();
      if (!venvExists) {
        return InstallResult(
          success: false,
          error: 'Virtual environment not found. Please create it first.',
        );
      }

      final venvPython = getVenvPythonCommand();
      onProgress?.call('Installing $packageName to virtual environment...');

      // Use pip with options to avoid long path issues:
      // --no-cache-dir: Don't use cache (avoids long temp paths)
      // --prefer-binary: Use pre-built wheels when possible
      // --upgrade: Ensure latest compatible version
      final process = await Process.start(
        venvPython,
        [
          '-m',
          'pip',
          'install',
          '--no-cache-dir',
          '--prefer-binary',
          packageName,
        ],
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

  /// Check if EasyOCR is installed (checks both venv and global installation)
  Future<bool> checkEasyOCR() async {
    // Check in venv first (if it exists)
    final venvExists = await checkVirtualEnvironment();
    if (venvExists) {
      try {
        final venvPython = getVenvPythonCommand();
        final result = await _shell.run('$venvPython -c "import easyocr"');
        if (result.first.exitCode == 0) {
          return true;
        }
      } catch (_) {
        // Continue to check globally
      }
    }

    // Check globally
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
  final String? packageName;
  final String? message;
  final String? error;

  const InstallResult({
    required this.success,
    this.packageName,
    this.message,
    this.error,
  });
}

/// Result of virtual environment creation
class CreateVenvResult {
  final bool success;
  final String? error;

  const CreateVenvResult({
    required this.success,
    this.error,
  });
}

