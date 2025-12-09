import 'package:flutter/material.dart' hide Flow;
import 'package:provider/provider.dart';
import '../providers/flow_provider.dart';
import '../models/flow.dart';

/// Dialog for creating/editing flows
class FlowFormDialog extends StatefulWidget {
  final Flow? flow;

  const FlowFormDialog({super.key, this.flow});

  @override
  State<FlowFormDialog> createState() => _FlowFormDialogState();
}

class _FlowFormDialogState extends State<FlowFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.flow?.name ?? '');
    _descriptionController = TextEditingController(text: widget.flow?.description ?? '');
  }

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
      title: Text(widget.flow == null ? 'New Flow' : 'Edit Flow'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Flow Name *',
                  hintText: 'e.g., Login Automation',
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.flow == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<FlowProvider>();
    final name = _nameController.text;
    final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;

    try {
      if (widget.flow == null) {
        // Create new flow
        await provider.createFlow(
          name: name,
          description: description,
        );
      } else {
        // Update existing flow
        final updated = widget.flow!.copyWith(
          name: name,
          description: description,
        );
        await provider.updateFlow(updated);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

