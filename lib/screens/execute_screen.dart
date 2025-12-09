import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/execution_provider.dart';
import '../providers/flow_provider.dart';
import '../providers/object_provider.dart';
import '../models/flow_variable.dart';
import '../models/execution_result.dart';
import '../models/flow.dart' as model;

/// Screen for executing flows with input/output configuration
class ExecuteScreen extends StatefulWidget {
  const ExecuteScreen({super.key});

  @override
  State<ExecuteScreen> createState() => _ExecuteScreenState();
}

class _ExecuteScreenState extends State<ExecuteScreen> {
  final Map<String, TextEditingController> _inputControllers = {};
  int _selectedFlowIndex = 0;
  List<String> _selectedInputVariables = [];
  List<String> _selectedOutputVariables = [];

  @override
  void dispose() {
    for (var controller in _inputControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Consumer<FlowProvider>(
        builder: (context, flowProvider, child) {
          if (flowProvider.flows.isEmpty) {
            return _buildNoFlowsAvailable();
          }

          // Adjust selected index if needed
          if (_selectedFlowIndex >= flowProvider.flows.length) {
            _selectedFlowIndex = 0;
          }

          final selectedFlow = flowProvider.flows[_selectedFlowIndex];

          return Row(
            children: [
              // Configuration panel
              SizedBox(
                width: 420,
                child: _buildConfigurationPanel(flowProvider, selectedFlow),
              ),
              Container(width: 1, color: const Color(0xFFB5B7BB)),
              // Execution panel
              Expanded(
                child: _buildExecutionPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoFlowsAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, size: 64, color: Color(0xFF56585C)),
          const SizedBox(height: 16),
          Text(
            'No flows available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF56585C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a flow in the Flow tab to execute it',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel(FlowProvider flowProvider, model.Flow selectedFlow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildConfigHeader(),
          Container(height: 1, color: const Color(0xFFB5B7BB)),
          _buildFlowSelector(flowProvider),
          Container(height: 1, color: const Color(0xFFB5B7BB)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(selectedFlow),
                  const SizedBox(height: 24),
                  _buildOutputSection(selectedFlow),
                ],
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFB5B7BB)),
          _buildExecuteButton(selectedFlow),
        ],
      ),
    );
  }

  Widget _buildConfigHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF56585C),
      child: const Row(
        children: [
          Icon(Icons.settings, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Flow Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowSelector(FlowProvider flowProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF252526) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Flow',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF56585C),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedFlowIndex,
            dropdownColor: isDark ? const Color(0xFF252526) : Colors.white,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF56585C),
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            items: List.generate(flowProvider.flows.length, (index) {
              final flow = flowProvider.flows[index];
              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  flow.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF56585C),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFlowIndex = value;
                  // Clear selections when changing flow
                  _selectedInputVariables.clear();
                  _selectedOutputVariables.clear();
                  _inputControllers.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(model.Flow selectedFlow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : Colors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: const Color(0xFFB5B7BB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Input Variables',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF56585C),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddInputDialog(selectedFlow),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C),
                  side: BorderSide(color: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedInputVariables.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No input variables selected',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            )
          else
            ..._selectedInputVariables.map((varName) {
              if (!_inputControllers.containsKey(varName)) {
                _inputControllers[varName] = TextEditingController();
              }
              return _buildInputField(varName);
            }),
        ],
      ),
    );
  }

  Widget _buildInputField(String varName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _inputControllers[varName],
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: varName,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
          hintText: 'Enter value',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.clear, size: 18, color: isDark ? Colors.white70 : null),
                onPressed: () {
                  _inputControllers[varName]?.clear();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedInputVariables.remove(varName);
                    _inputControllers[varName]?.dispose();
                    _inputControllers.remove(varName);
                  });
                },
                padding: const EdgeInsets.only(right: 8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        onChanged: (value) {
          final execProvider = context.read<ExecutionProvider>();
          execProvider.addInput(varName, value);
        },
      ),
    );
  }

  void _showAddInputDialog(model.Flow selectedFlow) async {
    // Analyze the flow code to find variables
    final analyzer = context.read<FlowProvider>();
    // Trigger analysis
    analyzer.selectFlow(selectedFlow.id);

    final variables = analyzer.currentVariables
        .where((v) => !_selectedInputVariables.contains(v.name))
        .toList();

    if (!mounted) return;

    if (variables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No variables found in the flow or all already selected'),
          backgroundColor: Color(0xFF56585C),
        ),
      );
      return;
    }

    final selected = await showDialog<FlowVariable>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Input Variable'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: variables.length,
            itemBuilder: (context, index) {
              final variable = variables[index];
              return ListTile(
                title: Text(variable.name),
                subtitle: Text('Line ${variable.lineNumber} • ${variable.inferredType ?? 'unknown type'}'),
                onTap: () => Navigator.of(context).pop(variable),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && !_selectedInputVariables.contains(selected.name)) {
      setState(() {
        _selectedInputVariables.add(selected.name);
      });
    }
  }

  Widget _buildOutputSection(model.Flow selectedFlow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : Colors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: const Color(0xFFB5B7BB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Output Variables',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF56585C),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddOutputDialog(selectedFlow),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C),
                  side: BorderSide(color: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedOutputVariables.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No output variables selected',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            )
          else
            ..._selectedOutputVariables.map((varName) => _buildOutputVariableChip(varName)),
        ],
      ),
    );
  }

  Widget _buildOutputVariableChip(String varName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF56585C).withValues(alpha: 0.3)
              : const Color(0xFF56585C).withValues(alpha: 0.1),
          border: Border.all(color: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C)),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              varName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF56585C),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedOutputVariables.remove(varName);
                });
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF56585C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOutputDialog(model.Flow selectedFlow) async {
    // Analyze the flow code to find variables
    final analyzer = context.read<FlowProvider>();
    analyzer.selectFlow(selectedFlow.id);

    final variables = analyzer.currentVariables
        .where((v) => !_selectedOutputVariables.contains(v.name))
        .toList();

    if (!mounted) return;

    if (variables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No variables found in the flow or all already selected'),
          backgroundColor: Color(0xFF56585C),
        ),
      );
      return;
    }

    final selected = await showDialog<FlowVariable>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Output Variable'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: variables.length,
            itemBuilder: (context, index) {
              final variable = variables[index];
              return ListTile(
                title: Text(variable.name),
                subtitle: Text('Line ${variable.lineNumber} • ${variable.inferredType ?? 'unknown type'}'),
                onTap: () => Navigator.of(context).pop(variable),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && !_selectedOutputVariables.contains(selected.name)) {
      setState(() {
        _selectedOutputVariables.add(selected.name);
      });
    }
  }

  Widget _buildExecuteButton(model.Flow selectedFlow) {
    return Consumer<ExecutionProvider>(
      builder: (context, execProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: execProvider.isExecuting
              ? ElevatedButton.icon(
                  onPressed: () => execProvider.cancelExecution(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Cancel Execution'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => _executeFlow(selectedFlow, execProvider),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Execute Flow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF56585C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildExecutionPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ExecutionProvider>(
      builder: (context, provider, child) {
        if (provider.currentExecution == null) {
          return Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle,
                    size: 64,
                    color: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to execute',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF56585C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure variables and click Execute to run the flow',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Column(
            children: [
              _buildExecutionHeader(provider.currentExecution!),
              Container(height: 1, color: const Color(0xFFB5B7BB)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusSection(provider.currentExecution!),
                      const SizedBox(height: 24),
                      _buildLogsSection(provider.currentExecution!),
                      const SizedBox(height: 24),
                      _buildOutputsSection(provider.currentExecution!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExecutionHeader(ExecutionResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF252526) : const Color(0xFFF5F5F5),
      child: Row(
        children: [
          Icon(Icons.analytics, color: isDark ? Colors.white : const Color(0xFF56585C)),
          const SizedBox(width: 8),
          Text(
            'Execution Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF56585C),
            ),
          ),
          const Spacer(),
          _buildStatusChip(result.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ExecutionStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ExecutionStatus.running:
        color = Colors.blue;
        icon = Icons.refresh;
        label = 'Running';
        break;
      case ExecutionStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Completed';
        break;
      case ExecutionStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        label = 'Failed';
        break;
      case ExecutionStatus.cancelled:
        color = Colors.orange;
        icon = Icons.cancel;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ExecutionResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF252526) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Execution ID', result.executionId),
            _buildInfoRow('Started', _formatTime(result.startTime)),
            if (result.endTime != null)
              _buildInfoRow('Ended', _formatTime(result.endTime!)),
            if (result.duration != null)
              _buildInfoRow('Duration', '${result.duration!.inMilliseconds}ms'),
            if (result.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${result.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection(ExecutionResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF252526) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logs (${result.logs.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: result.logs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No logs',
                        style: TextStyle(color: isDark ? Colors.white70 : null),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Copy all button
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                final allLogs = result.logs.join('\n');
                                Clipboard.setData(ClipboardData(text: allLogs));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Logs copied to clipboard')),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy All'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: result.logs.length,
                            itemBuilder: (context, index) {
                              final log = result.logs[index];
                              final isError = log.contains('[ERROR]');
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: SelectableText(
                                  log,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: isError
                                        ? Colors.red
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputsSection(ExecutionResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF252526) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outputs (${result.outputs.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 12),
            if (result.outputs.isEmpty)
              Text(
                'No outputs',
                style: TextStyle(color: isDark ? Colors.white70 : null),
              )
            else
              ...result.outputs.map((output) => _buildOutputItem(output)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputItem(VariableOutput output) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            output.variableName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Chip(
                  label: Text(output.type),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: isDark ? const Color(0xFF56585C) : null,
                  labelStyle: TextStyle(color: isDark ? Colors.white : null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    output.value.toString(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white70 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _executeFlow(model.Flow selectedFlow, ExecutionProvider execProvider) {
    // Update input values from controllers and configure execution provider
    execProvider.clearInputs();
    for (var entry in _inputControllers.entries) {
      final varName = entry.key;
      final value = entry.value.text;
      if (value.isNotEmpty) {
        execProvider.addInput(varName, value);
      }
    }

    // Set output variables
    execProvider.setOutputVariables(_selectedOutputVariables);

    // Get screen objects from provider
    final objectProvider = context.read<ObjectProvider>();
    final screenObjects = objectProvider.objects;

    // Execute the flow
    execProvider.executeFlow(
      flowId: selectedFlow.id,
      pythonCode: selectedFlow.pythonCode,
      screenObjects: screenObjects,
    );
  }
}

