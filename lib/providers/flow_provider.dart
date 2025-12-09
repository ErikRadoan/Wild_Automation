import 'package:flutter/foundation.dart';
import '../models/flow.dart';
import '../models/flow_variable.dart';
import '../services/storage_service.dart';
import '../services/code_analyzer_service.dart';
import 'package:uuid/uuid.dart';

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
}

