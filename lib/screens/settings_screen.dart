import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/localization_service.dart';
import '../services/python_dependency_service.dart';

/// Settings screen with theme, language, and Python setup
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _depService = PythonDependencyService();

  PythonCheckResult? _pythonStatus;
  Map<String, PackageStatus>? _packageStatuses;
  bool _venvExists = false;
  bool _isChecking = true;
  bool _isInstalling = false;
  bool _isCreatingVenv = false;
  final List<String> _installLogs = [];

  @override
  void initState() {
    super.initState();
    _checkDependencies();
  }

  Future<void> _checkDependencies() async {
    if (!mounted) return;

    setState(() {
      _isChecking = true;
      _installLogs.clear();
    });

    try {
      // Check Python
      final pythonStatus = await _depService.checkPython();
      if (!mounted) return;
      setState(() => _pythonStatus = pythonStatus);

      // Check if virtual environment exists
      final venvExists = await _depService.checkVirtualEnvironment();
      if (!mounted) return;
      setState(() => _venvExists = venvExists);

      if (pythonStatus.isInstalled) {
        // Check packages (will use venv if it exists)
        final packageStatuses = await _depService.checkPackages(pythonStatus.command!);
        if (!mounted) return;
        setState(() => _packageStatuses = packageStatuses);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installLogs.add('Error checking dependencies: $e');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isChecking = false);
    }
  }

  Future<void> _createVirtualEnvironment() async {
    if (_pythonStatus == null || !_pythonStatus!.isInstalled) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCreatingVenv = true;
      _installLogs.clear();
      _installLogs.add('Creating virtual environment at short path to avoid Windows MAX_PATH issues...');
    });

    try {
      final result = await _depService.createVirtualEnvironment(
        _pythonStatus!.command!,
        (log) {
          if (!mounted) return;
          setState(() {
            _installLogs.add(log);
          });
        },
      );

      if (result.success) {
        if (!mounted) return;
        setState(() {
          _installLogs.add('\n✓ Virtual environment created successfully!');
          _installLogs.add('All packages will be installed to: ${PythonDependencyService.venvPath}');
        });

        // Recheck dependencies
        await Future.delayed(const Duration(seconds: 1));
        await _checkDependencies();

        // Update the global settings service
        if (!mounted) return;
        final settings = context.read<SettingsService>();
        await settings.checkDependencies();
      } else {
        if (!mounted) return;
        setState(() {
          _installLogs.add('\n✗ Failed to create virtual environment: ${result.error}');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installLogs.add('\n✗ Error creating virtual environment: $e');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isCreatingVenv = false);
    }
  }

  Future<void> _installMissingPackages() async {
    if (_pythonStatus == null || !_pythonStatus!.isInstalled || _packageStatuses == null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isInstalling = true;
      _installLogs.clear();
    });

    try {
      // Create virtual environment first if it doesn't exist
      if (!_venvExists) {
        setState(() {
          _installLogs.add('Creating virtual environment first to avoid long path issues...');
        });

        await _createVirtualEnvironment();

        if (!_venvExists) {
          setState(() {
            _installLogs.add('✗ Cannot install packages without virtual environment');
          });
          return;
        }
      }

      setState(() {
        _installLogs.add('\nInstalling packages to virtual environment...');
        _installLogs.add('Using isolated Python environment: ${PythonDependencyService.venvPath}');
      });

      final results = await _depService.installMissingPackages(
        _pythonStatus!.command!,
        _packageStatuses!,
        (log) {
          if (!mounted) return;
          setState(() {
            _installLogs.add(log);
          });
        },
      );

      // Show results
      final success = results.where((r) => r.success).length;
      final failed = results.where((r) => !r.success).length;

      if (!mounted) return;
      setState(() {
        _installLogs.add('\n=== Installation Complete ===');
        _installLogs.add('Successfully installed: $success package(s)');
        if (failed > 0) {
          _installLogs.add('Failed: $failed package(s)');
        }
      });

      // Recheck dependencies
      await Future.delayed(const Duration(seconds: 1));
      await _checkDependencies();

      // Update the global settings service to unlock projects
      if (!mounted) return;
      final settings = context.read<SettingsService>();
      await settings.checkDependencies();

      // Show success message if all dependencies are now installed
      if (!settings.hasMissingDependencies) {
        setState(() {
          _installLogs.add('\n✅ All dependencies installed successfully!');
          _installLogs.add('You can now create and open projects.');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installLogs.add('Installation error: $e');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isInstalling = false);
    }
  }

  bool _hasMissingDependencies() {
    if (_packageStatuses == null) {
      return false;
    }

    for (var status in _packageStatuses!.values) {
      if (!status.isInstalled) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings),
            const SizedBox(width: 12),
            Text(loc.settings),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Appearance Section
          _buildSectionHeader(loc.theme, Icons.palette),
          const SizedBox(height: 16),
          _buildThemeSelector(settings, loc, isDark),
          const SizedBox(height: 32),

          // Language Section
          _buildSectionHeader(loc.language, Icons.language),
          const SizedBox(height: 16),
          _buildLanguageSelector(settings, loc, isDark),
          const SizedBox(height: 32),

          // Python Dependencies Section
          _buildSectionHeader('Python Dependencies', Icons.extension),
          const SizedBox(height: 16),
          _buildPythonSection(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(SettingsService settings, AppLocalizations loc, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  const Icon(Icons.dark_mode, size: 20),
                  const SizedBox(width: 12),
                  Text(loc.darkTheme),
                ],
              ),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) => settings.setTheme(value!),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  const Icon(Icons.light_mode, size: 20),
                  const SizedBox(width: 12),
                  Text(loc.lightTheme),
                ],
              ),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) => settings.setTheme(value!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(SettingsService settings, AppLocalizations loc, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<String>(
              title: Row(
                children: [
                  const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(loc.english),
                ],
              ),
              value: 'en',
              groupValue: settings.languageCode,
              onChanged: (value) => settings.setLanguage(value!),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            RadioListTile<String>(
              title: Row(
                children: [
                  const Text('🇩🇪', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(loc.german),
                ],
              ),
              value: 'de',
              groupValue: settings.languageCode,
              onChanged: (value) => settings.setLanguage(value!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPythonSection(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isChecking)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildPythonStatus(isDark),
              const SizedBox(height: 16),
              if (_pythonStatus?.isInstalled ?? false) ...[
                _buildPackagesStatus(isDark),
                const SizedBox(height: 16),
                if (_hasMissingDependencies())
                  ElevatedButton.icon(
                    onPressed: _isInstalling ? null : _installMissingPackages,
                    icon: _isInstalling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isInstalling ? 'Installing...' : 'Install Missing Packages'),
                  ),
                if (_installLogs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInstallLog(isDark),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPythonStatus(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _pythonStatus?.isInstalled ?? false ? Colors.green : Colors.red,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _pythonStatus?.isInstalled ?? false ? Icons.check_circle : Icons.error,
                color: _pythonStatus?.isInstalled ?? false ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Python Installation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pythonStatus?.isInstalled ?? false
                          ? _pythonStatus!.version!
                          : 'Python not found. Please install Python 3.7 or higher.',
                      style: TextStyle(
                        color: _pythonStatus?.isInstalled ?? false
                            ? (isDark ? Colors.white70 : Colors.grey[700])
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Virtual Environment Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _venvExists
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            border: Border.all(
              color: _venvExists ? Colors.green : Colors.orange,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _venvExists ? Icons.folder_special : Icons.info_outline,
                    color: _venvExists ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Virtual Environment',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _venvExists
                              ? 'Active at ${PythonDependencyService.venvPath}'
                              : 'Not configured (prevents Windows long path errors)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_venvExists && (_pythonStatus?.isInstalled ?? false)) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Create a virtual environment to avoid Windows MAX_PATH errors when installing EasyOCR',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isCreatingVenv ? null : _createVirtualEnvironment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isCreatingVenv
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_isCreatingVenv ? 'Creating...' : 'Create Virtual Environment'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackagesStatus(bool isDark) {
    if (_packageStatuses == null) {
      return const SizedBox();
    }

    final installed = _packageStatuses!.values.where((p) => p.isInstalled).length;
    final total = _packageStatuses!.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Python Packages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$installed / $total installed',
              style: TextStyle(
                color: installed == total ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._packageStatuses!.entries.map((entry) => _buildPackageItem(entry.value, isDark)),
      ],
    );
  }

  Widget _buildPackageItem(PackageStatus status, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: status.isInstalled ? Colors.green : Colors.orange,
        ),
        color: isDark ? const Color(0xFF252526) : Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            status.isInstalled ? Icons.check_circle_outline : Icons.download,
            color: status.isInstalled ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  status.isInstalled
                      ? 'Version: ${status.installedVersion}'
                      : 'Not installed (required: ${status.requiredVersion})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallLog(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Installation Log',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          color: isDark ? Colors.black87 : Colors.grey[900],
          child: ListView.builder(
            itemCount: _installLogs.length,
            itemBuilder: (context, index) {
              return Text(
                _installLogs[index],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.greenAccent,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

