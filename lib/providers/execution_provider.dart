import 'package:flutter/foundation.dart';
import '../models/execution_result.dart';
import '../models/flow_variable.dart';
import '../models/screen_object.dart';
import '../services/python_execution_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing flow execution
class ExecutionProvider extends ChangeNotifier {
  final PythonExecutionService _executionService;
  final _uuid = const Uuid();

  ExecutionResult? _currentExecution;
  List<ExecutionResult> _executionHistory = [];
  FlowIOConfig _ioConfig = const FlowIOConfig();
  bool _isExecuting = false;
  String? _error;

  ExecutionProvider(this._executionService);

  ExecutionResult? get currentExecution => _currentExecution;
  List<ExecutionResult> get executionHistory => _executionHistory;
  FlowIOConfig get ioConfig => _ioConfig;
  bool get isExecuting => _isExecuting;
  String? get error => _error;

  void setIOConfig(FlowIOConfig config) {
    _ioConfig = config;
    notifyListeners();
  }

  void addInput(String variableName, String value, {String? type}) {
    final input = VariableInput(
      variableName: variableName,
      value: value,
      type: type,
    );

    final inputs = List<VariableInput>.from(_ioConfig.inputs);
    final existingIndex = inputs.indexWhere((i) => i.variableName == variableName);

    if (existingIndex != -1) {
      inputs[existingIndex] = input;
    } else {
      inputs.add(input);
    }

    _ioConfig = _ioConfig.copyWith(inputs: inputs);
    notifyListeners();
  }

  void removeInput(String variableName) {
    final inputs = _ioConfig.inputs.where((i) => i.variableName != variableName).toList();
    _ioConfig = _ioConfig.copyWith(inputs: inputs);
    notifyListeners();
  }

  void clearInputs() {
    _ioConfig = _ioConfig.copyWith(inputs: []);
    notifyListeners();
  }

  void setOutputVariables(List<String> variableNames) {
    _ioConfig = _ioConfig.copyWith(outputVariables: variableNames);
    notifyListeners();
  }

  void toggleOutputVariable(String variableName) {
    final outputs = List<String>.from(_ioConfig.outputVariables);

    if (outputs.contains(variableName)) {
      outputs.remove(variableName);
    } else {
      outputs.add(variableName);
    }

    _ioConfig = _ioConfig.copyWith(outputVariables: outputs);
    notifyListeners();
  }

  void clearIOConfig() {
    _ioConfig = const FlowIOConfig();
    notifyListeners();
  }

  Future<void> executeFlow({
    required String flowId,
    required String pythonCode,
    required List<ScreenObject> screenObjects,
  }) async {
    if (_isExecuting) {
      _error = 'Another execution is already in progress';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _error = null;
    final executionId = _uuid.v4();

    _currentExecution = ExecutionResult.started(
      executionId: executionId,
      flowId: flowId,
    );
    notifyListeners();

    try {
      final result = await _executionService.executeFlow(
        executionId: executionId,
        flowId: flowId,
        pythonCode: pythonCode,
        ioConfig: _ioConfig,
        screenObjects: screenObjects,
        onLog: (log) {
          if (_currentExecution != null) {
            _currentExecution = _currentExecution!.addLog(log);
            notifyListeners();
          }
        },
      );

      _currentExecution = result;
      _executionHistory.insert(0, result);

      // Keep only last 50 executions
      if (_executionHistory.length > 50) {
        _executionHistory = _executionHistory.sublist(0, 50);
      }
    } catch (e) {
      _error = e.toString();

      // Print error to console for easy copying
      debugPrint('═══════════════════════════════════════════');
      debugPrint('FLOW EXECUTION ERROR');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Flow ID: $flowId');
      debugPrint('Error: $_error');
      debugPrint('═══════════════════════════════════════════');

      if (_currentExecution != null) {
        _currentExecution = _currentExecution!.copyWith(
          status: ExecutionStatus.failed,
          endTime: DateTime.now(),
          errorMessage: e.toString(),
        );

        // Print execution logs for debugging
        debugPrint('\nExecution Logs:');
        for (var log in _currentExecution!.logs) {
          debugPrint('  $log');
        }
        debugPrint('═══════════════════════════════════════════\n');
      }
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  Future<void> cancelExecution() async {
    if (!_isExecuting) return;

    try {
      await _executionService.cancelExecution();

      if (_currentExecution != null) {
        _currentExecution = _currentExecution!.copyWith(
          status: ExecutionStatus.cancelled,
          endTime: DateTime.now(),
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  void clearCurrentExecution() {
    _currentExecution = null;
    notifyListeners();
  }

  void clearHistory() {
    _executionHistory.clear();
    notifyListeners();
  }

  ExecutionResult? getExecutionById(String id) {
    try {
      return _executionHistory.firstWhere((e) => e.executionId == id);
    } catch (_) {
      return null;
    }
  }

  List<ExecutionResult> getExecutionsByFlowId(String flowId) {
    return _executionHistory.where((e) => e.flowId == flowId).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

