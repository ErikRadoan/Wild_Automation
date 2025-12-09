import 'package:equatable/equatable.dart';
import 'flow_variable.dart';

/// Result of flow execution
class ExecutionResult extends Equatable {
  final String executionId;
  final String flowId;
  final ExecutionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> logs;
  final List<VariableOutput> outputs;
  final String? errorMessage;
  final String? stackTrace;

  const ExecutionResult({
    required this.executionId,
    required this.flowId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.logs = const [],
    this.outputs = const [],
    this.errorMessage,
    this.stackTrace,
  });

  factory ExecutionResult.started({
    required String executionId,
    required String flowId,
  }) {
    return ExecutionResult(
      executionId: executionId,
      flowId: flowId,
      status: ExecutionStatus.running,
      startTime: DateTime.now(),
    );
  }

  ExecutionResult copyWith({
    ExecutionStatus? status,
    DateTime? endTime,
    List<String>? logs,
    List<VariableOutput>? outputs,
    String? errorMessage,
    String? stackTrace,
  }) {
    return ExecutionResult(
      executionId: executionId,
      flowId: flowId,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      logs: logs ?? this.logs,
      outputs: outputs ?? this.outputs,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  ExecutionResult addLog(String log) {
    return copyWith(logs: [...logs, log]);
  }

  ExecutionResult addOutput(VariableOutput output) {
    return copyWith(outputs: [...outputs, output]);
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isRunning => status == ExecutionStatus.running;
  bool get isCompleted => status == ExecutionStatus.completed;
  bool get isFailed => status == ExecutionStatus.failed;
  bool get isCancelled => status == ExecutionStatus.cancelled;

  @override
  List<Object?> get props => [
        executionId,
        flowId,
        status,
        startTime,
        endTime,
        logs,
        outputs,
        errorMessage,
      ];

  @override
  String toString() => 'ExecutionResult(id: $executionId, status: $status)';
}

/// Status of execution
enum ExecutionStatus {
  running,
  completed,
  failed,
  cancelled,
}

