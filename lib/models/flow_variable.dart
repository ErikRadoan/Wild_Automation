import 'package:equatable/equatable.dart';

/// Represents a variable found in Python code
class FlowVariable extends Equatable {
  final String name;
  final VariableType type;
  final int lineNumber;
  final String? inferredType;
  final String? defaultValue;

  const FlowVariable({
    required this.name,
    required this.type,
    required this.lineNumber,
    this.inferredType,
    this.defaultValue,
  });

  FlowVariable copyWith({
    String? name,
    VariableType? type,
    int? lineNumber,
    String? inferredType,
    String? defaultValue,
  }) {
    return FlowVariable(
      name: name ?? this.name,
      type: type ?? this.type,
      lineNumber: lineNumber ?? this.lineNumber,
      inferredType: inferredType ?? this.inferredType,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  List<Object?> get props => [name, type, lineNumber, inferredType, defaultValue];

  @override
  String toString() => 'FlowVariable(name: $name, type: $type, line: $lineNumber)';
}

/// Type of variable (input or output)
enum VariableType {
  input,
  output,
  both,
}

/// Input/Output configuration for flow execution
class FlowIOConfig extends Equatable {
  final List<VariableInput> inputs;
  final List<String> outputVariables;

  const FlowIOConfig({
    this.inputs = const [],
    this.outputVariables = const [],
  });

  FlowIOConfig copyWith({
    List<VariableInput>? inputs,
    List<String>? outputVariables,
  }) {
    return FlowIOConfig(
      inputs: inputs ?? this.inputs,
      outputVariables: outputVariables ?? this.outputVariables,
    );
  }

  @override
  List<Object?> get props => [inputs, outputVariables];
}

/// Input value for a variable
class VariableInput extends Equatable {
  final String variableName;
  final String value;
  final String? type;

  const VariableInput({
    required this.variableName,
    required this.value,
    this.type,
  });

  VariableInput copyWith({
    String? variableName,
    String? value,
    String? type,
  }) {
    return VariableInput(
      variableName: variableName ?? this.variableName,
      value: value ?? this.value,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [variableName, value, type];

  @override
  String toString() => 'VariableInput($variableName = $value)';
}

/// Output value from execution
class VariableOutput extends Equatable {
  final String variableName;
  final dynamic value;
  final String type;

  const VariableOutput({
    required this.variableName,
    required this.value,
    required this.type,
  });

  @override
  List<Object?> get props => [variableName, value, type];

  @override
  String toString() => 'VariableOutput($variableName = $value)';
}

