import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import '../models/flow.dart';
import '../models/flow_variable.dart';
import '../services/storage_service.dart';
import '../services/code_analyzer_service.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

/// Provider for managing flows
class FlowProvider extends ChangeNotifier {
  final StorageService _storage;
  final CodeAnalyzerService _codeAnalyzer;
  final _uuid = const Uuid();

  List<Flow> _flows = [];
  Flow? _currentFlow;
  List<FlowVariable> _currentVariables = [];
  bool _isLoading = false;
  String? _error;

  FlowProvider(this._storage, this._codeAnalyzer) {
    _loadFlows();
  }

  List<Flow> get flows => _flows;
  Flow? get currentFlow => _currentFlow;
  List<FlowVariable> get currentVariables => _currentVariables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadFlows() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _flows = _storage.getAllFlows();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Flow> createFlow({
    required String name,
    String? description,
    String pythonCode = '',
    List<String> tags = const [],
  }) async {
    try {
      final flow = Flow.create(
        id: _uuid.v4(),
        name: name,
        description: description,
        pythonCode: pythonCode,
        tags: tags,
      );

      await _storage.saveFlow(flow);
      _flows.add(flow);
      notifyListeners();

      return flow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFlow(Flow flow) async {
    try {
      await _storage.saveFlow(flow);
      final index = _flows.indexWhere((f) => f.id == flow.id);
      if (index != -1) {
        _flows[index] = flow;
        if (_currentFlow?.id == flow.id) {
          _currentFlow = flow;
          _analyzeCurrentFlow();
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFlow(String id) async {
    try {
      await _storage.deleteFlow(id);
      _flows.removeWhere((f) => f.id == id);
      if (_currentFlow?.id == id) {
        _currentFlow = null;
        _currentVariables = [];
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void selectFlow(String id) {
    try {
      _currentFlow = _flows.firstWhere((f) => f.id == id);
      _analyzeCurrentFlow();
      notifyListeners();
    } catch (_) {
      _error = 'Flow not found';
      notifyListeners();
    }
  }

  void deselectFlow() {
    _currentFlow = null;
    _currentVariables = [];
    notifyListeners();
  }

  void updateCurrentFlowCode(String code) {
    if (_currentFlow != null) {
      _currentFlow = _currentFlow!.copyWith(pythonCode: code);
      _analyzeCurrentFlow();
      notifyListeners();
    }
  }

  void _analyzeCurrentFlow() {
    if (_currentFlow != null) {
      _currentVariables = _codeAnalyzer.analyzeCode(_currentFlow!.pythonCode);
    } else {
      _currentVariables = [];
    }
  }

  Future<void> saveCurrentFlow() async {
    if (_currentFlow != null) {
      await updateFlow(_currentFlow!);
    }
  }

  Flow? getFlowById(String id) {
    try {
      return _flows.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Flow? getFlowByName(String name) {
    try {
      return _flows.firstWhere((f) => f.name == name);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Export a flow to a JSON file
  Future<bool> exportFlow(Flow flow) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Flow',
        fileName: '${flow.name}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final flowJson = flow.toJson();
        final jsonString = const JsonEncoder.withIndent('  ').convert(flowJson);
        final file = File(result);
        await file.writeAsString(jsonString);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Export failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Import a flow from a JSON file
  Future<Flow?> importFlow() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Flow',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final flowJson = jsonDecode(jsonString) as Map<String, dynamic>;

        // Generate new ID to avoid conflicts
        flowJson['id'] = _uuid.v4();
        flowJson['createdAt'] = DateTime.now().toIso8601String();
        flowJson['updatedAt'] = DateTime.now().toIso8601String();

        final flow = Flow.fromJson(flowJson);

        // Check if flow with same name exists
        if (_flows.any((f) => f.name == flow.name)) {
          flowJson['name'] = '${flow.name} (imported)';
          final renamedFlow = Flow.fromJson(flowJson);
          await _storage.saveFlow(renamedFlow);
          _flows.add(renamedFlow);
          notifyListeners();
          return renamedFlow;
        }

        await _storage.saveFlow(flow);
        _flows.add(flow);
        notifyListeners();
        return flow;
      }
      return null;
    } catch (e) {
      _error = 'Import failed: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
}

