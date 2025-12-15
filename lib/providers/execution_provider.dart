import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/execution_result.dart';
import '../models/flow_variable.dart';
import '../models/screen_object.dart';
import '../services/python_execution_service.dart';
import '../services/taskbar_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing flow execution
class ExecutionProvider extends ChangeNotifier {
  final PythonExecutionService _executionService;
  final _uuid = const Uuid();
  final _taskbarService = TaskbarService();

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

    // Show green badge on taskbar to indicate running
    await _taskbarService.showRunningBadge();

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

      // Send success notification
      await _sendNotification(
        title: 'Flow Complete',
        body: 'Flow execution finished successfully',
        isSuccess: true,
      );
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

      // Send error notification
      await _sendNotification(
        title: 'Flow Failed',
        body: 'Flow execution failed: ${e.toString()}',
        isSuccess: false,
      );
    } finally {
      _isExecuting = false;

      // Remove green badge from taskbar
      await _taskbarService.hideRunningBadge();

      notifyListeners();
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    required bool isSuccess,
  }) async {
    try {
      if (Platform.isWindows) {
        // Use PowerShell to show Windows Toast Notification
        final result = await Process.run('powershell', [
          '-WindowStyle', 'Hidden',
          '-Command',
          '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

\$APP_ID = "WILD.Automate"
\$template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text><![CDATA[$title]]></text>
            <text><![CDATA[$body]]></text>
            <image placement="appLogoOverride" hint-crop="circle" src="file:///\$env:APPDATA/WILD_Automate/icon.png"/>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" />
</toast>
"@

\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
\$toast.Tag = "wildAutomate"
\$toast.Group = "flowExecution"
\$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID)
\$notifier.Show(\$toast)
          '''
        ]);

        if (result.exitCode == 0) {
          debugPrint('✓ Notification sent: $title - $body');
        } else {
          debugPrint('⚠ Notification warning: ${result.stderr}');
        }
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
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

