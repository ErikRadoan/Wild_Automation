import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/localization_service.dart';
import '../main.dart' show MainScreen;
import 'settings_screen.dart';
import 'loading_screen.dart';


/// Initial screen for selecting or creating a project
class ProjectSelectionScreen extends StatefulWidget {
  final StorageService storage;

  const ProjectSelectionScreen({super.key, required this.storage});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  List<Project> _recentProjects = [];
  bool _isLoading = true;
  final _uuid = const Uuid();
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      // Fallback to default version if package info fails
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  Future<void> _loadRecentProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = widget.storage.getAllProjects();
      projects.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      setState(() {
        _recentProjects = projects.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          child: Card(
            elevation: 0,
            color: isDark ? const Color(0xFF2D2D30) : Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Row(
              children: [
                // Left panel - Actions
                Container(
                  width: 300,
                  color: const Color(0xFF56585C),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo/Title
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'WILD',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            TextSpan(
                              text: ' Automate',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.appSubtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Actions
                      _buildActionButton(
                        icon: Icons.create_new_folder,
                        label: loc.newProject,
                        onTap: settings.hasMissingDependencies ? null : _createNewProject,
                        disabled: settings.hasMissingDependencies,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        icon: Icons.folder_open,
                        label: loc.openProject,
                        onTap: settings.hasMissingDependencies ? null : _openExistingProject,
                        disabled: settings.hasMissingDependencies,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        icon: settings.hasMissingDependencies ? Icons.settings : Icons.tune,
                        label: loc.settings,
                        onTap: _openSettings,
                        showWarning: settings.hasMissingDependencies,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        icon: Icons.info_outline,
                        label: loc.about,
                        onTap: _showAbout,
                      ),

                      const Spacer(),

                      // Warning message if dependencies missing
                      if (settings.hasMissingDependencies)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Missing dependencies!\nGo to Settings to install.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Footer
                      Text(
                        '${loc.version} $_appVersion',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Right panel - Recent projects
                Expanded(
                  child: _buildRecentProjects(settings, loc, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool disabled = false,
    bool showWarning = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              if (showWarning)
                const Icon(Icons.error, color: Colors.orange, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentProjects(SettingsService settings, AppLocalizations loc, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Text(
            loc.recentProjects,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF56585C),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AnimatedGear(
                        size: 80,
                        color: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading projects...',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : _recentProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_off,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.noRecentProjects,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.createOrOpenProject,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recentProjects.length,
                      itemBuilder: (context, index) {
                        final project = _recentProjects[index];
                        return _buildProjectCard(project, settings, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project, SettingsService settings, bool isDark) {
    final canOpen = !settings.hasMissingDependencies;

    return Opacity(
      opacity: canOpen ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: isDark ? const Color(0xFF252526) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: InkWell(
          onTap: canOpen ? () => _openProject(project) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFFB5B7BB),
                  child: const Icon(Icons.folder, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.path,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          project.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _showProjectOptions(project),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewProject() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _NewProjectDialog(),
    );

    if (result != null) {
      final name = result['name']!;
      final description = result['description'];

      // Get documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final projectPath = '${docsDir.path}\\WILD Projects\\$name';

      // Create project directory
      final dir = Directory(projectPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Create project
      final project = Project.create(
        id: _uuid.v4(),
        name: name,
        path: projectPath,
        description: description,
      );

      await widget.storage.saveProject(project);

      if (mounted) {
        _openProject(project);
      }
    }
  }

  Future<void> _openExistingProject() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Project Directory',
    );

    if (result != null) {
      final dir = Directory(result);
      final name = dir.path.split(Platform.pathSeparator).last;

      final project = Project.create(
        id: _uuid.v4(),
        name: name,
        path: result,
      );

      await widget.storage.saveProject(project);

      if (mounted) {
        _openProject(project);
      }
    }
  }

  Future<void> _openProject(Project project) async {
    // Update last opened time
    final updated = project.copyWith(lastOpenedAt: DateTime.now());
    await widget.storage.saveProject(updated);

    if (mounted) {
      // Navigate directly to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(
            project: updated,
            storage: widget.storage,
          ),
        ),
      );
    }
  }

  void _showProjectOptions(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(project.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${project.path}'),
            const SizedBox(height: 8),
            Text('Created: ${_formatDate(project.createdAt)}'),
            Text('Last opened: ${_formatDate(project.lastOpenedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.storage.deleteProject(project.id);
              Navigator.pop(context);
              _loadRecentProjects();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    ).then((_) {
      // Reload projects after returning from settings in case dependencies were fixed
      _loadRecentProjects();
    });
  }

  void _showAbout() {
    final _ = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'WILD',
                style: TextStyle(
                  color: Color(0xFF56585C),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              TextSpan(
                text: ' Automate',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version $_appVersion'),
            const SizedBox(height: 16),
            const Text('UI Automation Made Simple'),
            const SizedBox(height: 16),
            const Text('Developed by the WILD group.'),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} WILD group. All rights reserved.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Animated gear widget for loading states
class _AnimatedGear extends StatefulWidget {
  final double size;
  final Color color;

  const _AnimatedGear({
    required this.size,
    required this.color,
  });

  @override
  State<_AnimatedGear> createState() => _AnimatedGearState();
}

class _AnimatedGearState extends State<_AnimatedGear> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159265359,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: GearPainter(
          color: widget.color,
          teethCount: 12,
        ),
      ),
    );
  }
}


/// Dialog for creating a new project
class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: const Text('New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                hintText: 'My Automation Project',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

