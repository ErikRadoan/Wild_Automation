# Wild Automation Auto-Updater

This directory contains the auto-updater executable for Wild Automation.

## Overview

The updater is a standalone executable that handles the update process:

1. **Download**: Downloads the latest release from GitHub
2. **Extract**: Extracts the new version
3. **Migrate**: Moves user data to the new version
4. **Replace**: Replaces the old executable with the new one
5. **Launch**: Launches the updated application
6. **Cleanup**: Removes temporary files and itself

## Building the Updater

### Prerequisites
- Dart SDK 3.9.2 or higher

### Build Instructions

Run the build script from the project root:

```powershell
.\build_updater.ps1
```

This will:
1. Navigate to the `updater` directory
2. Get dependencies via `dart pub get`
3. Compile the updater to a native executable (`updater.exe`)
4. Copy the executable to the project root

The compiled `updater.exe` must be included in your release packages.

## How It Works

### Main Application
When the user clicks "Update Now" in the settings:

1. The main app calls `UpdateService.startUpdate()`
2. This launches `updater.exe` with arguments:
   - Download URL for the new release
   - Path to current executable
   - Process ID (for waiting)
3. The main app closes

### Updater Process
The updater then:

1. Waits for the main app to close completely
2. Downloads the new release ZIP file
3. Extracts it to a temporary directory
4. Finds the new executable
5. Backs up the current executable
6. Copies the new executable to replace the old one
7. Merges any data directories (preserving user data)
8. Launches the new version
9. Cleans up temporary files
10. Deletes itself (after a delay)

## Release Checklist

When creating a new release:

1. ✅ Update version in `lib/services/update_service.dart`:
   - `currentVersion` string
   - `currentBuildNumber` integer

2. ✅ Build the updater:
   ```powershell
   .\build_updater.ps1
   ```

3. ✅ Build the main application:
   ```powershell
   flutter build windows --release
   ```

4. ✅ Include `updater.exe` in the release package:
   - Must be in the same directory as `wild_automation.exe`

5. ✅ Create a ZIP file with the release

6. ✅ Upload to GitHub Releases with proper naming:
   - Format: `WILD_Automate_v{version}+{build}.zip`
   - Example: `WILD_Automate_v1.6.0+14.zip`

## Troubleshooting

### Updater Not Found
If users see "Updater not found" error:
- Ensure `updater.exe` is included in the release ZIP
- Check that it's in the same directory as the main executable

### Update Fails
The updater creates detailed logs in its console window. Check:
- Network connectivity
- Disk space
- File permissions
- Antivirus interference

### Manual Update
If auto-update fails, users can:
1. Download the latest release manually
2. Extract it
3. Copy their data directory from the old version
4. Run the new version

## Development

### Modify the Updater
Edit `updater/updater.dart` and rebuild:

```powershell
.\build_updater.ps1
```

### Test the Updater
To test locally:

1. Build a release version
2. Create a ZIP file
3. Host it somewhere (or use a local path)
4. Modify `UpdateService` to point to your test URL
5. Run the main app and trigger an update

**Warning**: Testing will replace your executable. Have a backup!

## Architecture

```
wild_automation/
├── lib/
│   └── services/
│       └── update_service.dart    # Checks for updates, launches updater
├── updater/
│   ├── updater.dart               # Updater logic
│   └── pubspec.yaml               # Updater dependencies
├── build_updater.ps1              # Build script
└── updater.exe                    # Compiled updater (in releases)
```

## Security Considerations

- Updates are downloaded from GitHub's official release CDN
- The updater verifies the executable exists before replacing
- User data is preserved during updates
- Backup of old executable is created (and cleaned up on success)
- The updater runs with the same permissions as the main app

## License

Same as Wild Automation (MIT License)

