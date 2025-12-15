import 'package:flutter/material.dart' hide Flow;
import 'package:provider/provider.dart';
import '../providers/flow_provider.dart';
import '../models/flow.dart';
import '../widgets/flow_form_dialog.dart';
import '../widgets/code_editor_widget.dart';
import '../services/localization_service.dart';

/// Screen for managing flows
class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Flow list sidebar
          SizedBox(
            width: 300,
            child: _buildFlowList(),
          ),
          const VerticalDivider(width: 1),
          // Code editor
          Expanded(
            child: _buildCodeEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowList() {
    return Column(
      children: [
        _buildFlowListHeader(),
        const Divider(height: 1),
        Expanded(
          child: Consumer<FlowProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.flows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No flows created',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: provider.flows.length,
                itemBuilder: (context, index) {
                  final flow = provider.flows[index];
                  final isSelected = provider.currentFlow?.id == flow.id;
                  return _buildFlowListItem(flow, isSelected);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlowListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.code),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Flows',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importFlow,
            tooltip: 'Import Flow',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportCurrentFlow,
            tooltip: 'Export Flow',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateFlowDialog,
            tooltip: 'New Flow',
          ),
        ],
      ),
    );
  }

  Widget _buildFlowListItem(Flow flow, bool isSelected) {
    return ListTile(
      selected: isSelected,
      leading: const Icon(Icons.description),
      title: Text(flow.name),
      subtitle: flow.description != null ? Text(flow.description!) : null,
      onTap: () {
        context.read<FlowProvider>().selectFlow(flow.id);
      },
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _showEditFlowDialog(flow);
          } else if (value == 'delete') {
            _confirmDeleteFlow(flow);
          }
        },
      ),
    );
  }

  Widget _buildCodeEditor() {
    return Consumer<FlowProvider>(
      builder: (context, provider, child) {
        if (provider.currentFlow == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.code, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Select a flow to edit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'or create a new one to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildEditorHeader(provider),
            const Divider(height: 1),
            Expanded(
              child: CodeEditorWidget(
                key: ValueKey(provider.currentFlow!.id), // Add key to force recreation when flow changes
                initialCode: provider.currentFlow!.pythonCode,
                onCodeChanged: (code) {
                  provider.updateCurrentFlowCode(code);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditorHeader(FlowProvider provider) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentFlow!.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (provider.currentFlow!.description != null)
                  Text(
                    provider.currentFlow!.description!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await provider.saveCurrentFlow();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.flowSaved)),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showCreateFlowDialog() {
    showDialog(
      context: context,
      builder: (context) => const FlowFormDialog(),
    );
  }

  void _showEditFlowDialog(Flow flow) {
    showDialog(
      context: context,
      builder: (context) => FlowFormDialog(flow: flow),
    );
  }

  void _confirmDeleteFlow(Flow flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flow'),
        content: Text('Are you sure you want to delete "${flow.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FlowProvider>().deleteFlow(flow.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFlow() async {
    final provider = context.read<FlowProvider>();
    final flow = await provider.importFlow();

    if (mounted) {
      if (flow != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flow "${flow.name}" imported successfully')),
        );
        provider.selectFlow(flow.id);
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    }
  }

  Future<void> _exportCurrentFlow() async {
    final provider = context.read<FlowProvider>();
    final currentFlow = provider.currentFlow;

    if (currentFlow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flow selected to export')),
      );
      return;
    }

    final success = await provider.exportFlow(currentFlow);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flow "${currentFlow.name}" exported successfully')),
        );
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    }
  }
}

