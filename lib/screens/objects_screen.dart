import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/object_provider.dart';
import '../providers/overlay_provider.dart';
import '../models/screen_object.dart';
import '../widgets/object_form_dialog.dart';
import 'overlay_screen.dart';

/// Screen for managing screen objects
class ObjectsScreen extends StatelessWidget {
  const ObjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildObjectList(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        tooltip: 'New Object',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screen Objects',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Define points and rectangles on your screen',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showPreview(context),
            icon: const Icon(Icons.visibility),
            label: const Text('Live Preview'),
            style: ElevatedButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context) async {
    final provider = context.read<ObjectProvider>();
    if (provider.objects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No objects to preview')),
      );
      return;
    }

    // Convert objects to overlay objects
    final overlayObjects = provider.objects.map((obj) => OverlayObject(
      name: obj.name,
      isPoint: obj.isPoint,
      x: obj.x,
      y: obj.y,
      x2: obj.x2,
      y2: obj.y2,
    )).toList();

    // Enter overlay mode
    context.read<OverlayProvider>().enterObjectPreviewMode(overlayObjects);
  }

  Widget _buildObjectList(BuildContext context) {
    return Consumer<ObjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.objects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No screen objects yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Create your first object to get started'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Object'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.objects.length,
          itemBuilder: (context, index) {
            final object = provider.objects[index];
            return _buildObjectCard(context, object);
          },
        );
      },
    );
  }

  Widget _buildObjectCard(BuildContext context, ScreenObject object) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: object.isPoint ? Colors.blue : Colors.green,
          child: Icon(
            object.isPoint ? Icons.my_location : Icons.crop_square,
            color: Colors.white,
          ),
        ),
        title: Text(object.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              object.isPoint
                  ? 'Point: (${object.x}, ${object.y})'
                  : 'Rectangle: (${object.x}, ${object.y}) to (${object.x2}, ${object.y2}) [${object.width}×${object.height}]',
            ),
            if (object.description != null) ...[
              const SizedBox(height: 4),
              Text(
                object.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, object),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, object),
              tooltip: 'Delete',
            ),
          ],
        ),
        isThreeLine: object.description != null,
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ObjectFormDialog(),
    );
  }

  void _showEditDialog(BuildContext context, ScreenObject object) {
    showDialog(
      context: context,
      builder: (context) => ObjectFormDialog(object: object),
    );
  }

  void _confirmDelete(BuildContext context, ScreenObject object) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Delete Object'),
        content: Text('Are you sure you want to delete "${object.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ObjectProvider>().deleteObject(object.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

