import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

/// Wild Automation Updater with GUI
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(600, 400),
    center: true,
    title: 'WILD Automation Updater',
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(UpdaterApp(args: args));
}

class UpdaterApp extends StatelessWidget {
  final List<String> args;

  const UpdaterApp({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WILD Automation Updater',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: UpdaterScreen(args: args),
    );
  }
}

class UpdaterScreen extends StatefulWidget {
  final List<String> args;

  const UpdaterScreen({super.key, required this.args});

  @override
  State<UpdaterScreen> createState() => _UpdaterScreenState();
}

class _UpdaterScreenState extends State<UpdaterScreen> {
  final List<String> _logs = [];
  double _progress = 0.0;
  String _currentStep = 'Initializing...';
  bool _isComplete = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startUpdate();
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  void _updateProgress(double progress, String step) {
    setState(() {
      _progress = progress;
      _currentStep = step;
    });
  }

  Future<void> _startUpdate() async {
    if (widget.args.length < 3) {
      _log('ERROR: Invalid arguments');
      _log('Usage: updater.exe <download_url> <current_exe_path> <process_id>');
      setState(() {
        _hasError = true;
        _currentStep = 'Error: Invalid arguments';
      });
      return;
    }

    final downloadUrl = widget.args[0];
    final currentExePath = widget.args[1];
    final processIdString = widget.args[2];
    final currentProcessId = int.tryParse(processIdString);

    _log('=== WILD Automation Updater ===');
    _log('Download URL: $downloadUrl');
    _log('Current EXE: $currentExePath');
    _log('Process ID: $processIdString');

    try {
      // Step 1: Wait for main application to close
      _updateProgress(0.05, 'Waiting for application to close...');
      _log('[1/8] Waiting for main application to close...');

      if (currentProcessId != null) {
        // Wait for the process to actually close
        int attempts = 0;
        while (attempts < 30) {  // 30 seconds max
          try {
            // Check if process still exists
            final result = await Process.run('tasklist', ['/FI', 'PID eq $currentProcessId', '/NH']);
            if (!result.stdout.toString().contains(processIdString)) {
              _log('✓ Main process closed');
              break;
            }
          } catch (e) {
            // Process not found, it's closed
            _log('✓ Main process closed');
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }

        // Extra delay to ensure file handles are released
        await Future.delayed(const Duration(seconds: 1));
      } else {
        // Fallback: just wait a bit
        await Future.delayed(const Duration(seconds: 3));
        _log('✓ Waited for application to close');
      }

      // Step 2: Download the new version
      _updateProgress(0.15, 'Downloading update...');
      _log('[2/8] Downloading update from GitHub...');
      final downloadPath = await _downloadFile(downloadUrl);
      _log('✓ Download complete: $downloadPath');

      // Step 3: Extract the archive
      _updateProgress(0.40, 'Extracting update...');
      _log('[3/8] Extracting update archive...');
      final currentDir = path.dirname(currentExePath);
      final tempExtractDir = path.join(currentDir, 'update_temp');
      await _extractArchive(downloadPath, tempExtractDir);
      _log('✓ Extraction complete');

      // Step 4: Find the release folder (might be nested in ZIP)
      _updateProgress(0.50, 'Locating files...');
      _log('[4/8] Locating release files...');
      final releaseDir = await _findReleaseDirectory(tempExtractDir);
      if (releaseDir == null) {
        throw Exception('Could not find release files in extracted archive');
      }
      _log('✓ Found release directory: $releaseDir');

      // Step 5: Backup current installation
      _updateProgress(0.60, 'Creating backup...');
      _log('[5/8] Creating backup of current installation...');
      final backupDir = path.join(currentDir, 'backup_${DateTime.now().millisecondsSinceEpoch}');
      await Directory(backupDir).create();
      await File(currentExePath).copy(path.join(backupDir, path.basename(currentExePath)));
      _log('✓ Backup created: $backupDir');

      // Step 6: Replace files
      _updateProgress(0.70, 'Replacing application files...');
      _log('[6/8] Replacing application files...');
      await _replaceFiles(releaseDir, currentDir, currentExePath);
      _log('✓ Files replaced successfully');

      // Step 7: Launch new version
      _updateProgress(0.90, 'Launching updated application...');
      _log('[7/8] Launching updated application...');
      final newExePath = currentExePath;
      await Process.start(
        newExePath,
        [],
        mode: ProcessStartMode.detached,
        workingDirectory: currentDir,
      );
      _log('✓ Application launched');

      // Step 8: Cleanup
      _updateProgress(0.95, 'Cleaning up...');
      _log('[8/8] Cleaning up temporary files...');
      try {
        await Directory(tempExtractDir).delete(recursive: true);
        await File(downloadPath).delete();
        if (await Directory(backupDir).exists()) {
          // Keep backup for safety
          _log('Note: Backup kept at: $backupDir');
        }
        _log('✓ Cleanup complete');
      } catch (e) {
        _log('Warning: Some temporary files could not be deleted: $e');
      }

      // Done!
      _updateProgress(1.0, 'Update complete!');
      _log('');
      _log('=== Update Successful! ===');
      _log('The application has been updated and launched.');
      _log('This updater will now close...');

      setState(() {
        _isComplete = true;
      });

      await Future.delayed(const Duration(seconds: 3));

      // Self-delete the old updater and exit
      final currentUpdaterPath = Platform.resolvedExecutable;
      final oldUpdaterPath = '$currentUpdaterPath.old';

      try {
        // Rename current updater so it can be deleted
        await File(currentUpdaterPath).rename(oldUpdaterPath);

        // Create a batch script to delete the old updater after this process exits
        final batchScript = path.join(currentDir, 'cleanup_updater.bat');
        final batchContent = '''
@echo off
timeout /t 2 /nobreak > nul
del /f /q "$oldUpdaterPath" 2>nul
del /f /q "%~f0" 2>nul
''';
        await File(batchScript).writeAsString(batchContent);

        // Execute the batch script
        await Process.start(
          'cmd',
          ['/c', batchScript],
          mode: ProcessStartMode.detached,
          runInShell: false,
        );
      } catch (e) {
        _log('Note: Old updater cleanup will happen on next update');
      }

      exit(0);
    } catch (e, stackTrace) {
      _log('');
      _log('❌ ERROR: $e');
      _log('Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      _log('');
      _log('Update failed. Please download and install manually from GitHub.');

      setState(() {
        _hasError = true;
        _currentStep = 'Update failed';
      });
    }
  }

  Future<String> _downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final tempDir = Directory.systemTemp;
    final downloadPath = path.join(
      tempDir.path,
      'wild_automation_update_${DateTime.now().millisecondsSinceEpoch}.zip',
    );

    final file = File(downloadPath);
    await file.writeAsBytes(response.bodyBytes);

    return downloadPath;
  }

  Future<void> _extractArchive(String archivePath, String targetDir) async {
    await Directory(targetDir).create(recursive: true);

    final bytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = path.join(targetDir, file.name);

      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }
  }

  /// Find the directory containing the actual release files
  /// GitHub releases might have a parent folder in the ZIP
  Future<String?> _findReleaseDirectory(String extractDir) async {
    final dir = Directory(extractDir);

    // First check if executable is directly in extract dir
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
        return extractDir;
      }
    }

    // Check one level deep for a subdirectory with the executable
    await for (final entity in dir.list(recursive: false)) {
      if (entity is Directory) {
        final subDir = Directory(entity.path);
        await for (final subEntity in subDir.list(recursive: false)) {
          if (subEntity is File && subEntity.path.toLowerCase().endsWith('.exe')) {
            return entity.path;
          }
        }
      }
    }

    return null;
  }

  Future<void> _replaceFiles(String sourceDir, String targetDir, String currentExePath) async {
    final source = Directory(sourceDir);
    final currentExeName = path.basename(currentExePath);
    final currentUpdaterExe = Platform.resolvedExecutable;
    final currentUpdaterName = path.basename(currentUpdaterExe);

    // Copy all files from source to target
    await for (final entity in source.list(recursive: false)) {
      final name = path.basename(entity.path);
      final targetPath = path.join(targetDir, name);

      // Skip the currently running updater executable
      if (name.toLowerCase() == currentUpdaterName.toLowerCase()) {
        _log('  Skipped (running): $name');
        continue;
      }

      if (entity is File) {
        try {
          // For the main executable, try a few times in case it's still releasing file handles
          if (name.toLowerCase() == currentExeName.toLowerCase()) {
            int attempts = 0;
            while (attempts < 5) {
              try {
                if (await File(targetPath).exists()) {
                  await File(targetPath).delete();
                }
                await entity.copy(targetPath);
                _log('  Replaced: $name');
                break;
              } catch (e) {
                attempts++;
                if (attempts >= 5) {
                  rethrow;
                }
                await Future.delayed(const Duration(milliseconds: 500));
              }
            }
          } else {
            // Regular file
            if (await File(targetPath).exists()) {
              await File(targetPath).delete();
            }
            await entity.copy(targetPath);
            _log('  Copied: $name');
          }
        } catch (e) {
          _log('  Warning: Could not replace $name: $e');
        }
      } else if (entity is Directory) {
        // For directories, copy recursively
        try {
          if (!await Directory(targetPath).exists()) {
            await Directory(targetPath).create();
          }
          await _copyDirectory(entity.path, targetPath);
          _log('  Copied directory: $name');
        } catch (e) {
          _log('  Warning: Could not copy directory $name: $e');
        }
      }
    }
  }

  Future<void> _copyDirectory(String source, String destination) async {
    final sourceDir = Directory(source);
    final destDir = Directory(destination);

    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: false)) {
      final name = path.basename(entity.path);
      final destPath = path.join(destination, name);

      if (entity is File) {
        await entity.copy(destPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity.path, destPath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.system_update, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'WILD Automation Updater',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _hasError ? Colors.red : (_isComplete ? Colors.green : Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasError ? Colors.red : (_isComplete ? Colors.green : Colors.blue),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Log section
            const Text(
              'Update Log:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Courier New',
                          color: log.contains('ERROR') || log.contains('❌')
                              ? Colors.red
                              : log.contains('✓')
                                  ? Colors.green
                                  : log.contains('Warning')
                                      ? Colors.orange
                                      : Colors.grey[300],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom buttons
            if (_hasError || _isComplete) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_hasError)
                    ElevatedButton(
                      onPressed: () => exit(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Close'),
                    ),
                  if (_isComplete)
                    ElevatedButton(
                      onPressed: () => exit(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Close'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

