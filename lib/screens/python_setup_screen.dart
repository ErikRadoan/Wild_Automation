import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../services/python_dependency_service.dart';
import '../main.dart' show MainScreen;

/// Screen for checking and installing Python dependencies
class PythonSetupScreen extends StatefulWidget {
  final Project? project;
  final StorageService storage;

  const PythonSetupScreen({
    super.key,
    this.project,
    required this.storage,
  });

  @override
  State<PythonSetupScreen> createState() => _PythonSetupScreenState();
}

class _PythonSetupScreenState extends State<PythonSetupScreen> {
  final _depService = PythonDependencyService();

  PythonCheckResult? _pythonStatus;
  Map<String, PackageStatus>? _packageStatuses;
  bool? _easyocrInstalled;
  bool _isChecking = true;
  bool _isInstalling = false;
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

      if (pythonStatus.isInstalled) {
        // Check packages
        final packageStatuses = await _depService.checkPackages(pythonStatus.command!);
        if (!mounted) return;
        setState(() => _packageStatuses = packageStatuses);

        // Check EasyOCR
        final easyocrInstalled = await _depService.checkEasyOCR();
        if (!mounted) return;
        setState(() => _easyocrInstalled = easyocrInstalled);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: const Color(0xFF56585C),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.extension, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Python ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Dependencies',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Checking and installing required Python packages',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isChecking
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPythonStatus(),
                              const SizedBox(height: 24),
                              if (_pythonStatus?.isInstalled ?? false) ...[
                                _buildPackagesStatus(),
                                const SizedBox(height: 24),
                                _buildEasyOCRStatus(),
                                if (_installLogs.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _buildInstallLog(),
                                ],
                              ],
                            ],
                          ),
                        ),
                ),

                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFB5B7BB))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.project == null
                            ? () => Navigator.pop(context)
                            : null,
                        child: const Text('Back'),
                      ),
                      Row(
                        children: [
                          if (_pythonStatus?.isInstalled ?? false)
                            ElevatedButton.icon(
                              onPressed: (_isInstalling || _isChecking || _hasMissingDependencies() == false)
                                  ? null
                                  : _installMissingPackages,
                              icon: _isInstalling
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(_isInstalling ? 'Installing...' : 'Install Missing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF56585C),
                              ),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _canContinue() ? _continue : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(widget.project == null ? 'Done' : 'Continue'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPythonStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB5B7BB)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _pythonStatus?.isInstalled ?? false
                      ? _pythonStatus!.version!
                      : 'Python not found. Please install Python 3.7 or higher.',
                  style: TextStyle(
                    color: _pythonStatus?.isInstalled ?? false
                        ? Colors.grey[700]
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesStatus() {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        ..._packageStatuses!.entries.map((entry) => _buildPackageItem(entry.value)),
      ],
    );
  }

  Widget _buildPackageItem(PackageStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: status.isInstalled ? Colors.green : Colors.orange,
        ),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEasyOCRStatus() {
    // Check if easyocr is in the package list
    final easyocrPackage = _packageStatuses?['easyocr'];
    final isInstalled = easyocrPackage?.isInstalled ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB5B7BB)),
      ),
      child: Row(
        children: [
          Icon(
            isInstalled ? Icons.check_circle : Icons.info,
            color: isInstalled ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EasyOCR (OCR Engine)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isInstalled
                      ? 'EasyOCR is installed. Full OCR features available with GPU acceleration support.'
                      : 'EasyOCR not found. Install it to enable OCR features.\n'
                      'Note: First run will download language models (~100MB).',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (!isInstalled) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '💡 EasyOCR is easier than Tesseract - no system installation needed!',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Installation Log',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          color: Colors.black87,
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

  bool _hasMissingDependencies() {
    if (_packageStatuses == null && _easyocrInstalled == null) {
      return false; // Not checked yet
    }

    // Check if any packages are missing
    if (_packageStatuses != null) {
      for (var status in _packageStatuses!.values) {
        if (!status.isInstalled) {
          return true;
        }
      }
    }

    // Check if EasyOCR is missing
    if (_easyocrInstalled == false) {
      return true;
    }

    return false;
  }

  bool _canContinue() {
    if (_pythonStatus == null || !_pythonStatus!.isInstalled) {
      return false;
    }

    // Allow continuing if Python is installed, even if packages are missing
    // User can install them later
    return true;
  }

  void _continue() {
    if (widget.project == null) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(
            project: widget.project!,
            storage: widget.storage,
          ),
        ),
      );
    }
  }
}

