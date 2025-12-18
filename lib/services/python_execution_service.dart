import 'dart:async';
import 'dart:io';
import 'package:process_run/process_run.dart';
import '../models/execution_result.dart';
import '../models/flow_variable.dart';
import '../models/screen_object.dart';
import '../api/automation_api_generator.dart';

/// Service for executing Python code
class PythonExecutionService {
  final Shell _shell = Shell();
  Process? _currentProcess;

  /// Execute Python code with input/output handling
  Future<ExecutionResult> executeFlow({
    required String executionId,
    required String flowId,
    required String pythonCode,
    required FlowIOConfig ioConfig,
    required List<ScreenObject> screenObjects,
    void Function(String)? onLog,
  }) async {
    var result = ExecutionResult.started(
      executionId: executionId,
      flowId: flowId,
    );

    // Create log file for full execution logs
    final logFile = await _createLogFile(executionId);
    IOSink? logSink;

    try {
      logSink = logFile.openWrite();
      logSink.writeln('=== Execution Started: ${DateTime.now()} ===');
      logSink.writeln('Flow ID: $flowId');
      logSink.writeln('Execution ID: $executionId');
      logSink.writeln('=' * 70);
      logSink.writeln();

      // Check if Python is available
      final pythonCommand = await _getPythonCommand();
      if (pythonCommand == null) {
        logSink.writeln('[ERROR] Python is not installed or not found in PATH');
        await logSink.flush();
        return result.copyWith(
          status: ExecutionStatus.failed,
          endTime: DateTime.now(),
          errorMessage: 'Python is not installed or not found in PATH',
          logFilePath: logFile.path,
        );
      }

      // Inject input variables into the code
      final modifiedCode = _injectInputs(pythonCode, ioConfig.inputs);

      // Add output tracking
      final codeWithOutputs = _addOutputTracking(modifiedCode, ioConfig.outputVariables);

      // Create wild_api.py file in temp directory
      await _createWildAPIFile(screenObjects);

      // Create temporary Python file
      final tempFile = await _createTempFile(codeWithOutputs);

      try {
        // Execute the Python script
        final process = await Process.start(pythonCommand, [tempFile.path]);
        _currentProcess = process;

        final stdoutCompleter = Completer<String>();
        final stderrCompleter = Completer<String>();

        final stdoutBuffer = StringBuffer();
        final stderrBuffer = StringBuffer();

        // Listen to stdout
        process.stdout.listen(
          (data) {
            final text = String.fromCharCodes(data);
            stdoutBuffer.write(text);

            // Parse and add logs
            for (final line in text.split('\n')) {
              if (line.isNotEmpty) {
                // Write to log file (full output)
                logSink?.writeln(line);

                // Add to result (limited to 500 lines)
                result = result.addLog(line);
                onLog?.call(line);
              }
            }
          },
          onDone: () => stdoutCompleter.complete(stdoutBuffer.toString()),
        );

        // Listen to stderr
        process.stderr.listen(
          (data) {
            final text = String.fromCharCodes(data);
            stderrBuffer.write(text);

            // Add error logs
            for (final line in text.split('\n')) {
              if (line.isNotEmpty) {
                final errorLine = '[ERROR] $line';

                // Write to log file (full output)
                logSink?.writeln(errorLine);

                // Add to result (limited to 500 lines)
                result = result.addLog(errorLine);
                onLog?.call(errorLine);
              }
            }
          },
          onDone: () => stderrCompleter.complete(stderrBuffer.toString()),
        );

        // Wait for process to complete
        final exitCode = await process.exitCode;
        final stdout = await stdoutCompleter.future;
        final stderr = await stderrCompleter.future;

        // Parse outputs from stdout
        final outputs = _parseOutputs(stdout, ioConfig.outputVariables);

        // Write completion to log file
        logSink.writeln();
        logSink.writeln('=' * 70);
        logSink.writeln('=== Execution Completed: ${DateTime.now()} ===');
        logSink.writeln('Exit Code: $exitCode');
        logSink.writeln('Status: ${exitCode == 0 ? "SUCCESS" : "FAILED"}');
        await logSink.flush();

        if (exitCode == 0) {
          result = result.copyWith(
            status: ExecutionStatus.completed,
            endTime: DateTime.now(),
            outputs: outputs,
            logFilePath: logFile.path,
          );
        } else {
          result = result.copyWith(
            status: ExecutionStatus.failed,
            endTime: DateTime.now(),
            errorMessage: 'Python script exited with code $exitCode',
            stackTrace: stderr,
            outputs: outputs,
            logFilePath: logFile.path,
          );
        }
      } finally {
        // Cleanup temp file
        await tempFile.delete();
        _currentProcess = null;
      }
    } catch (e, stackTrace) {
      logSink?.writeln('[EXCEPTION] $e');
      logSink?.writeln(stackTrace.toString());
      await logSink?.flush();

      result = result.copyWith(
        status: ExecutionStatus.failed,
        endTime: DateTime.now(),
        errorMessage: e.toString(),
        stackTrace: stackTrace.toString(),
        logFilePath: logFile.path,
      );
    } finally {
      await logSink?.close();
    }

    return result;
  }

  /// Cancel current execution
  Future<void> cancelExecution() async {
    if (_currentProcess != null) {
      _currentProcess!.kill();
      _currentProcess = null;
    }
  }

  /// Get Python command (prefer venv, fallback to system Python)
  Future<String?> _getPythonCommand() async {
    // First, check if virtual environment exists
    const venvPath = 'C:\\wild_venv';
    final venvPython = File('$venvPath\\Scripts\\python.exe');

    if (await venvPython.exists()) {
      return venvPython.path;
    }

    // Fallback to system Python
    // Try python3 first
    try {
      final result = await _shell.run('python3 --version');
      if (result.first.exitCode == 0) {
        return 'python3';
      }
    } catch (_) {}

    // Try python
    try {
      final result = await _shell.run('python --version');
      if (result.first.exitCode == 0) {
        return 'python';
      }
    } catch (_) {}

    return null;
  }

  /// Inject input variables at the beginning of the code
  String _injectInputs(String code, List<VariableInput> inputs) {
    final buffer = StringBuffer();

    // UTF-8 encoding declaration
    buffer.writeln('# -*- coding: utf-8 -*-');
    buffer.writeln('import sys');
    buffer.writeln('import io');
    buffer.writeln();
    buffer.writeln('# Configure stdout to use UTF-8 encoding');
    buffer.writeln('sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")');
    buffer.writeln();

    // ALWAYS inject the Wild API import
    buffer.writeln('# Wild Automation API - Auto-imported');
    buffer.writeln('from wild_api import *');
    buffer.writeln();

    if (inputs.isNotEmpty) {
      buffer.writeln('# Injected input variables');
      for (final input in inputs) {
        final value = _formatPythonValue(input.value, input.type);
        buffer.writeln('${input.variableName} = $value');
      }
      buffer.writeln();
    }

    buffer.write(code);

    return buffer.toString();
  }

  /// Format value for Python based on type
  String _formatPythonValue(String value, String? type) {
    if (type == null || type == 'unknown') {
      // Try to infer
      if (value == 'true' || value == 'false') {
        return value == 'true' ? 'True' : 'False';
      }
      if (int.tryParse(value) != null) {
        return value;
      }
      if (double.tryParse(value) != null) {
        return value;
      }
      // Default to string
      return '"${value.replaceAll('"', '\\"')}"';
    }

    switch (type.toLowerCase()) {
      case 'str':
      case 'string':
        return '"${value.replaceAll('"', '\\"')}"';
      case 'int':
      case 'integer':
        return value;
      case 'float':
      case 'double':
        return value;
      case 'bool':
      case 'boolean':
        return value == 'true' ? 'True' : 'False';
      default:
        return value;
    }
  }

  /// Add output tracking to the code
  String _addOutputTracking(String code, List<String> outputVariables) {
    if (outputVariables.isEmpty) return code;

    final buffer = StringBuffer(code);
    buffer.writeln();
    buffer.writeln('# Output variable tracking');
    buffer.writeln('print("\\n=== OUTPUTS ===" )');

    for (final varName in outputVariables) {
      buffer.writeln('try:');
      buffer.writeln('    print(f"$varName={type($varName).__name__}:{$varName}")');
      buffer.writeln('except:');
      buffer.writeln('    print("$varName=undefined:None")');
    }

    return buffer.toString();
  }

  /// Parse outputs from stdout
  List<VariableOutput> _parseOutputs(String stdout, List<String> outputVariables) {
    final outputs = <VariableOutput>[];

    // Find the outputs section
    if (!stdout.contains('=== OUTPUTS ===')) {
      return outputs;
    }

    final outputSection = stdout.split('=== OUTPUTS ===').last;
    final lines = outputSection.split('\n');

    for (final line in lines) {
      final match = RegExp(r'^(\w+)=(\w+):(.*)$').firstMatch(line.trim());
      if (match != null) {
        final varName = match.group(1)!;
        final typeName = match.group(2)!;
        final value = match.group(3)!;

        outputs.add(VariableOutput(
          variableName: varName,
          value: value,
          type: typeName,
        ));
      }
    }

    return outputs;
  }

  /// Create temporary Python file
  Future<File> _createTempFile(String code) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/wild_automation_${DateTime.now().millisecondsSinceEpoch}.py');
    await tempFile.writeAsString(code);
    return tempFile;
  }

  /// Create log file for execution logs
  Future<File> _createLogFile(String executionId) async {
    final tempDir = Directory.systemTemp;
    final logsDir = Directory('${tempDir.path}/wild_automation_logs');

    // Create logs directory if it doesn't exist
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    // Create log file with execution ID
    final logFile = File('${logsDir.path}/run_$executionId.log');
    return logFile;
  }

  /// Create wild_api.py file with full automation API
  Future<void> _createWildAPIFile(List<ScreenObject> screenObjects) async {
    final tempDir = Directory.systemTemp;
    final apiFile = File('${tempDir.path}/wild_api.py');

    // Convert ScreenObjects to map format for API generator
    final screenObjectsMap = <String, dynamic>{};
    for (final obj in screenObjects) {
      screenObjectsMap[obj.name] = {
        'type': obj.isPoint ? 'point' : 'rectangle',
        'x': obj.x,
        'y': obj.y,
        if (!obj.isPoint) 'width': (obj.x2! - obj.x).abs(),
        if (!obj.isPoint) 'height': (obj.y2! - obj.y).abs(),
        'description': obj.description ?? (obj.isPoint ? 'Point object' : 'Rectangle object'),
      };
    }

    // Use AutomationAPIGenerator for complete API including File class
    final apiContent = AutomationAPIGenerator.generatePythonAPI(
      screenObjects: screenObjectsMap,
      windowTargets: {}, // Empty for now, can be extended later
    );

    // Write to file
    await apiFile.writeAsString(apiContent);
  }

  // Old _generateWildAPI method removed - now using AutomationAPIGenerator
}

