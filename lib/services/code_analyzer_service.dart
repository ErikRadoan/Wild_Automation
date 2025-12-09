import '../models/flow_variable.dart';

/// Service for analyzing Python code to extract variables
class CodeAnalyzerService {
  /// Extract public variables from Python code
  List<FlowVariable> analyzeCode(String pythonCode) {
    final variables = <String, FlowVariable>{};
    final lines = pythonCode.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineNumber = i + 1;

      // Skip comments and empty lines
      if (line.isEmpty || line.startsWith('#')) continue;

      // Find variable assignments (simple pattern matching)
      final assignmentMatch = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.+)$')
          .firstMatch(line);

      if (assignmentMatch != null) {
        final varName = assignmentMatch.group(1)!;
        final value = assignmentMatch.group(2)!.trim();

        // Skip private variables (starting with _)
        if (varName.startsWith('_')) continue;

        // Infer type from value
        final inferredType = _inferType(value);

        // Determine if it's input (used before assignment) or output
        final type = _determineVariableType(varName, i, lines);

        variables[varName] = FlowVariable(
          name: varName,
          type: type,
          lineNumber: lineNumber,
          inferredType: inferredType,
          defaultValue: value,
        );
      }
    }

    return variables.values.toList()..sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
  }

  /// Infer type from the value string
  String _inferType(String value) {
    // Remove comments
    value = value.split('#')[0].trim();

    // Check for string literals
    if (value.startsWith('"') || value.startsWith("'")) {
      return 'str';
    }

    // Check for boolean
    if (value == 'True' || value == 'False') {
      return 'bool';
    }

    // Check for None
    if (value == 'None') {
      return 'None';
    }

    // Check for numbers
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return 'int';
    }

    if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
      return 'float';
    }

    // Check for list
    if (value.startsWith('[')) {
      return 'list';
    }

    // Check for dict
    if (value.startsWith('{')) {
      return 'dict';
    }

    // Check for tuple
    if (value.startsWith('(')) {
      return 'tuple';
    }

    return 'unknown';
  }

  /// Determine if variable is input, output, or both
  VariableType _determineVariableType(String varName, int assignmentLine, List<String> lines) {
    bool usedBefore = false;
    bool usedAfter = false;

    // Check if variable is used before assignment (indicating it might be input)
    for (var i = 0; i < assignmentLine; i++) {
      if (_isVariableUsed(varName, lines[i])) {
        usedBefore = true;
        break;
      }
    }

    // Check if variable is used after assignment (indicating it might be output)
    for (var i = assignmentLine + 1; i < lines.length; i++) {
      if (_isVariableUsed(varName, lines[i])) {
        usedAfter = true;
        break;
      }
    }

    // Variables at the top are typically inputs
    if (assignmentLine < 5 && !usedBefore) {
      return VariableType.input;
    }

    // Variables used after are outputs
    if (usedAfter) {
      return VariableType.output;
    }

    // Default to input for early variables, output for later ones
    return assignmentLine < lines.length ~/ 2
        ? VariableType.input
        : VariableType.output;
  }

  /// Check if a variable is used in a line
  bool _isVariableUsed(String varName, String line) {
    // Remove strings to avoid false positives
    line = line.replaceAll(RegExp(r'"[^"]*"'), '');
    line = line.replaceAll(RegExp(r"'[^']*'"), '');

    // Check if variable name appears (as a whole word)
    return RegExp(r'\b' + varName + r'\b').hasMatch(line);
  }

  /// Validate Python code syntax (basic check)
  ValidationResult validateSyntax(String pythonCode) {
    final errors = <String>[];
    final warnings = <String>[];
    final lines = pythonCode.split('\n');

    int indentLevel = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // Skip empty lines and comments
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;

      // Check for common syntax errors

      // Unmatched quotes
      final singleQuotes = _countUnescapedChars(line, "'");
      final doubleQuotes = _countUnescapedChars(line, '"');

      if (singleQuotes % 2 != 0) {
        errors.add('Line $lineNumber: Unmatched single quote');
      }
      if (doubleQuotes % 2 != 0) {
        errors.add('Line $lineNumber: Unmatched double quote');
      }

      // Check for unmatched parentheses
      final openParens = _countChars(line, '(');
      final closeParens = _countChars(line, ')');
      if (openParens != closeParens) {
        warnings.add('Line $lineNumber: Unmatched parentheses');
      }

      // Check indentation (simplified)
      final leadingSpaces = line.length - line.trimLeft().length;
      if (leadingSpaces % 4 != 0 && leadingSpaces % 2 != 0) {
        warnings.add('Line $lineNumber: Inconsistent indentation');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  int _countUnescapedChars(String str, String char) {
    int count = 0;
    bool escaped = false;
    for (var i = 0; i < str.length; i++) {
      if (escaped) {
        escaped = false;
        continue;
      }
      if (str[i] == '\\') {
        escaped = true;
        continue;
      }
      if (str[i] == char) {
        count++;
      }
    }
    return count;
  }

  int _countChars(String str, String char) {
    return char.allMatches(str).length;
  }
}

/// Result of code validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

