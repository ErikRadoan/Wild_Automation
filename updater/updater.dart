import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

/// Wild Automation Updater
///
/// This executable handles the update process:
/// 1. Downloads the new release
/// 2. Extracts it
/// 3. Moves user data to the new version
/// 4. Replaces the old executable
/// 5. Launches the new version
/// 6. Cleans up and deletes itself

void main(List<String> args) async {
  print('=== WILD Automation Updater ===\n');

  if (args.length < 3) {
    print('Usage: updater.exe <download_url> <current_exe_path> <current_process_id>');
    print('\nPress Enter to exit...');
    stdin.readLineSync();
    exit(1);
  }

  final downloadUrl = args[0];
  final currentExePath = args[1];
  final currentProcessId = args[2];

  print('Download URL: $downloadUrl');
  print('Current EXE: $currentExePath');
  print('Process ID: $currentProcessId\n');

  try {
    // Step 1: Wait for main application to close
    print('[1/7] Waiting for main application to close...');
    await Future.delayed(const Duration(seconds: 2));
    print('✓ Application closed\n');

    // Step 2: Download the new version
    print('[2/7] Downloading update...');
    final downloadPath = await downloadFile(downloadUrl);
    print('✓ Download complete: $downloadPath\n');

    // Step 3: Extract the archive
    print('[3/7] Extracting update...');
    final currentDir = path.dirname(currentExePath);
    final tempExtractDir = path.join(currentDir, 'update_temp');
    await extractArchive(downloadPath, tempExtractDir);
    print('✓ Extraction complete\n');

    // Step 4: Find the new executable
    print('[4/7] Locating new executable...');
    final newExePath = await findExecutable(tempExtractDir);
    if (newExePath == null) {
      throw Exception('Could not find new executable in extracted files');
    }
    print('✓ Found: $newExePath\n');

    // Step 5: Backup and replace
    print('[5/7] Replacing application files...');
    final backupPath = '$currentExePath.backup';

    // Backup old executable
    if (await File(currentExePath).exists()) {
      await File(currentExePath).copy(backupPath);
      await File(currentExePath).delete();
    }

    // Copy new executable
    await File(newExePath).copy(currentExePath);

    // Copy data directory if it exists in new version
    final newDataDir = path.join(path.dirname(newExePath), 'data');
    final currentDataDir = path.join(currentDir, 'data');

    if (await Directory(newDataDir).exists()) {
      // If data directory exists in update, merge it
      await copyDirectory(newDataDir, currentDataDir, overwrite: false);
    }

    print('✓ Files replaced successfully\n');

    // Step 6: Launch new version
    print('[6/7] Launching updated application...');
    await Process.start(
      currentExePath,
      [],
      mode: ProcessStartMode.detached,
    );
    print('✓ Application launched\n');

    // Step 7: Cleanup
    print('[7/7] Cleaning up...');

    // Delete temporary extraction directory
    try {
      await Directory(tempExtractDir).delete(recursive: true);
    } catch (e) {
      print('Warning: Could not delete temp directory: $e');
    }

    // Delete downloaded archive
    try {
      await File(downloadPath).delete();
    } catch (e) {
      print('Warning: Could not delete download: $e');
    }

    // Delete backup after successful launch
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (await File(backupPath).exists()) {
        await File(backupPath).delete();
      }
    } catch (e) {
      print('Warning: Could not delete backup: $e');
    }

    print('✓ Cleanup complete\n');

    print('=== Update Successful! ===');
    print('The application has been updated and launched.');
    print('This window will close in 3 seconds...');

    await Future.delayed(const Duration(seconds: 3));
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ ERROR: $e');
    print('\nStack trace:\n$stackTrace');
    print('\n\nUpdate failed. Please download and install manually.');
    print('Press Enter to exit...');
    stdin.readLineSync();
    exit(1);
  }
}

/// Download file from URL
Future<String> downloadFile(String url) async {
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

/// Extract ZIP archive
Future<void> extractArchive(String archivePath, String targetDir) async {
  // Create target directory
  await Directory(targetDir).create(recursive: true);

  // Read archive
  final bytes = await File(archivePath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  // Extract files
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

/// Find the main executable in extracted files
Future<String?> findExecutable(String directory) async {
  final dir = Directory(directory);

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      final name = path.basename(entity.path);
      if (name.toLowerCase() == 'wild_automation.exe' ||
          name.toLowerCase() == 'wild automate.exe') {
        return entity.path;
      }
    }
  }

  return null;
}

/// Copy directory contents
Future<void> copyDirectory(
  String source,
  String destination, {
  bool overwrite = true,
}) async {
  final sourceDir = Directory(source);
  final destDir = Directory(destination);

  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }

  await for (final entity in sourceDir.list(recursive: false)) {
    final name = path.basename(entity.path);
    final destPath = path.join(destination, name);

    if (entity is File) {
      if (overwrite || !await File(destPath).exists()) {
        await entity.copy(destPath);
      }
    } else if (entity is Directory) {
      await copyDirectory(entity.path, destPath, overwrite: overwrite);
    }
  }
}

