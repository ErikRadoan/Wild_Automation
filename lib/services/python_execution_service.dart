import 'dart:async';
import 'dart:io';
import 'package:process_run/process_run.dart';
import '../models/execution_result.dart';
import '../models/flow_variable.dart';
import '../models/screen_object.dart';

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

    try {
      // Check if Python is available
      final pythonCommand = await _getPythonCommand();
      if (pythonCommand == null) {
        return result.copyWith(
          status: ExecutionStatus.failed,
          endTime: DateTime.now(),
          errorMessage: 'Python is not installed or not found in PATH',
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
                result = result.addLog('[ERROR] $line');
                onLog?.call('[ERROR] $line');
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

        if (exitCode == 0) {
          result = result.copyWith(
            status: ExecutionStatus.completed,
            endTime: DateTime.now(),
            outputs: outputs,
          );
        } else {
          result = result.copyWith(
            status: ExecutionStatus.failed,
            endTime: DateTime.now(),
            errorMessage: 'Python script exited with code $exitCode',
            stackTrace: stderr,
            outputs: outputs,
          );
        }
      } finally {
        // Cleanup temp file
        await tempFile.delete();
        _currentProcess = null;
      }
    } catch (e, stackTrace) {
      result = result.copyWith(
        status: ExecutionStatus.failed,
        endTime: DateTime.now(),
        errorMessage: e.toString(),
        stackTrace: stackTrace.toString(),
      );
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

  /// Get Python command (python or python3)
  Future<String?> _getPythonCommand() async {
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

  /// Create wild_api.py file with full automation API
  Future<void> _createWildAPIFile(List<ScreenObject> screenObjects) async {
    final tempDir = Directory.systemTemp;
    final apiFile = File('${tempDir.path}/wild_api.py');

    // Generate the API content with screen objects
    final apiContent = _generateWildAPI(screenObjects);

    // Write to file
    await apiFile.writeAsString(apiContent);
  }

  /// Generate the complete Wild API Python code
  String _generateWildAPI(List<ScreenObject> screenObjects) {
    // Generate ScreenObject class definitions
    final screenObjectsCode = StringBuffer();
    screenObjectsCode.writeln('class ScreenObjects:');
    screenObjectsCode.writeln('    """Access to defined screen objects"""');

    if (screenObjects.isEmpty) {
      screenObjectsCode.writeln('    pass');
    } else {
      for (final obj in screenObjects) {
        screenObjectsCode.writeln();
        screenObjectsCode.writeln('    class ${obj.name}:');
        screenObjectsCode.writeln('        """${obj.description ?? (obj.isPoint ? 'Point object' : 'Rectangle object')}"""');
        screenObjectsCode.writeln('        name = "${obj.name}"');
        screenObjectsCode.writeln('        is_point = ${obj.isPoint ? 'True' : 'False'}');
        screenObjectsCode.writeln('        x = ${obj.x}');
        screenObjectsCode.writeln('        y = ${obj.y}');
        if (!obj.isPoint) {
          screenObjectsCode.writeln('        x2 = ${obj.x2}');
          screenObjectsCode.writeln('        y2 = ${obj.y2}');
          screenObjectsCode.writeln('        width = ${(obj.x2! - obj.x).abs()}');
          screenObjectsCode.writeln('        height = ${(obj.y2! - obj.y).abs()}');
        }
      }
    }

    return '''
import pyautogui
import time
import subprocess
import sys
from typing import Tuple, Optional

# Wild Automation API
# Auto-generated - DO NOT MODIFY

${screenObjectsCode.toString()}

class Window:
    """Window control functions"""
    
    @staticmethod
    def get_window_by_title(title: str):
        """Get window handle by title (returns hwnd or None)"""
        try:
            import win32gui
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    if title.lower() in window_title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            return windows[0] if windows else None
        except:
            return None
    
    @staticmethod
    def get_window_by_process(process_name: str):
        """Get window handle by process name (e.g., 'chrome.exe')"""
        try:
            import win32gui
            import win32process
            import psutil
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    _, pid = win32process.GetWindowThreadProcessId(hwnd)
                    try:
                        proc = psutil.Process(pid)
                        if proc.name().lower() == process_name.lower():
                            windows.append(hwnd)
                    except:
                        pass
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            return windows[0] if windows else None
        except:
            return None
    
    @staticmethod
    def get_window_info(title_or_handle):
        """Get detailed window information (title, process, handle)"""
        try:
            import win32gui
            import win32process
            import psutil
            
            # If it's a number, treat as handle
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if not hwnd:
                return None
            
            title = win32gui.GetWindowText(hwnd)
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            
            try:
                proc = psutil.Process(pid)
                process_name = proc.name()
                process_exe = proc.exe()
            except:
                process_name = "Unknown"
                process_exe = "Unknown"
            
            return {
                'handle': hwnd,
                'title': title,
                'process_name': process_name,
                'process_exe': process_exe,
                'pid': pid
            }
        except:
            return None
    
    @staticmethod
    def list_windows():
        """List all visible windows with their info"""
        try:
            import win32gui
            import win32process
            import psutil
            
            windows = []
            
            def callback(hwnd, _):
                if win32gui.IsWindowVisible(hwnd):
                    title = win32gui.GetWindowText(hwnd)
                    if title:  # Only include windows with titles
                        _, pid = win32process.GetWindowThreadProcessId(hwnd)
                        try:
                            proc = psutil.Process(pid)
                            process_name = proc.name()
                        except:
                            process_name = "Unknown"
                        
                        windows.append({
                            'handle': hwnd,
                            'title': title,
                            'process_name': process_name
                        })
                return True
            
            win32gui.EnumWindows(callback, None)
            return windows
        except:
            return []
    
    @staticmethod
    def activate(title_or_handle) -> bool:
        """Activate/focus a window by title or handle"""
        try:
            import win32gui
            import win32con
            
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if hwnd:
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                win32gui.SetForegroundWindow(hwnd)
                return True
            return False
        except Exception as e:
            print("[Window] Error activating: " + str(e))
            return False
    
    @staticmethod
    def focus(title_or_handle) -> bool:
        """Focus on a window and wait for it to become interactable
        
        This method brings the window to the foreground and waits until it's ready
        to accept input. The flow execution pauses until the window is focused.
        
        Usage:
            Window.focus("Google Chrome")  # Focus Chrome window
            Window.focus(hwnd)             # Focus by handle
        
        Returns:
            bool: True if window was successfully focused, False otherwise
        """
        try:
            import win32gui
            import win32con
            import time
            
            # Get window handle
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if not hwnd:
                print(f"[Window.focus] Window not found: {title_or_handle}")
                return False
            
            print(f"[Window.focus] Focusing window: {win32gui.GetWindowText(hwnd)}")
            
            # Restore if minimized
            if win32gui.IsIconic(hwnd):
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                time.sleep(0.1)
            
            # Bring to foreground
            win32gui.SetForegroundWindow(hwnd)
            
            # Wait for window to become the active foreground window
            max_attempts = 50  # 5 seconds timeout (50 * 0.1s)
            attempt = 0
            
            while attempt < max_attempts:
                # Check if this is now the foreground window
                current_foreground = win32gui.GetForegroundWindow()
                if current_foreground == hwnd:
                    # Additional check: ensure window is visible and enabled
                    if win32gui.IsWindowVisible(hwnd) and win32gui.IsWindowEnabled(hwnd):
                        print(f"[Window.focus] Window focused successfully after {attempt * 0.1:.1f}s")
                        time.sleep(0.1)  # Small delay to ensure it's interactable
                        return True
                
                time.sleep(0.1)
                attempt += 1
                
                # Try to set foreground again every 10 attempts
                if attempt % 10 == 0:
                    try:
                        win32gui.SetForegroundWindow(hwnd)
                    except:
                        pass
            
            print(f"[Window.focus] Warning: Timeout waiting for window to focus")
            # Return True anyway as the window may be focused but checks failed
            return True
            
        except Exception as e:
            print(f"[Window.focus] Error: {str(e)}")
            return False
    
    @staticmethod
    def maximize(title_or_handle) -> bool:
        """Maximize a window by title or handle"""
        try:
            import win32gui
            import win32con
            
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if hwnd:
                # First restore if minimized, then maximize
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                win32gui.ShowWindow(hwnd, win32con.SW_MAXIMIZE)
                return True
            
            print("[Window] Could not find window: " + str(title_or_handle))
            return False
        except Exception as e:
            print("[Window] Error maximizing: " + str(e))
            return False
    
    @staticmethod
    def minimize(title_or_handle) -> bool:
        """Minimize a window by title or handle"""
        try:
            import win32gui
            import win32con
            
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if hwnd:
                win32gui.ShowWindow(hwnd, win32con.SW_MINIMIZE)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def restore(title_or_handle) -> bool:
        """Restore a window by title or handle"""
        try:
            import win32gui
            import win32con
            
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if hwnd:
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def close(title_or_handle) -> bool:
        """Close a window by title or handle"""
        try:
            import win32gui
            import win32con
            
            if isinstance(title_or_handle, int):
                hwnd = title_or_handle
            else:
                hwnd = Window.get_window_by_title(title_or_handle)
            
            if hwnd:
                win32gui.PostMessage(hwnd, win32con.WM_CLOSE, 0, 0)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def get_active() -> str:
        """Get active window title"""
        try:
            import win32gui
            hwnd = win32gui.GetForegroundWindow()
            return win32gui.GetWindowText(hwnd)
        except:
            return ""
    
    @staticmethod
    def exists(title_or_handle) -> bool:
        """Check if window exists"""
        try:
            if isinstance(title_or_handle, int):
                import win32gui
                return win32gui.IsWindow(title_or_handle)
            else:
                return Window.get_window_by_title(title_or_handle) is not None
        except:
            return False

class Mouse:
    """Mouse control functions"""
    
    @staticmethod
    def click(x_or_object, y=None, button: str = 'left', clicks: int = 1):
        """Click at coordinates or screen object
        
        Usage:
            Mouse.click(100, 200)  # Click at x=100, y=200
            Mouse.click(ScreenObjects.MyPoint)  # Click at point object
        """
        # Handle screen object parameter
        if y is None:
            # First parameter is a screen object
            if not hasattr(x_or_object, 'x') or not hasattr(x_or_object, 'y'):
                raise ValueError("Invalid parameter: expected coordinates (x, y) or a screen object with x, y attributes")
            
            if hasattr(x_or_object, 'is_point') and not x_or_object.is_point:
                # Rectangle object - click at center
                x1, y1 = x_or_object.x, x_or_object.y
                x2, y2 = x_or_object.x2, x_or_object.y2
                x = (x1 + x2) // 2
                y = (y1 + y2) // 2
                print(f"[Mouse] Clicking at center of rectangle '{x_or_object.name}': ({x}, {y})")
            else:
                # Point object
                x = x_or_object.x
                y = x_or_object.y
                print(f"[Mouse] Clicking at point '{x_or_object.name}': ({x}, {y})")
        else:
            # Regular x, y coordinates
            x = x_or_object
        
        pyautogui.click(x, y, button=button, clicks=clicks)
    
    @staticmethod
    def move(x_or_object, y=None, duration: float = 0.0):
        """Move mouse to coordinates or screen object
        
        Usage:
            Mouse.move(100, 200)  # Move to x=100, y=200
            Mouse.move(ScreenObjects.MyPoint)  # Move to point object
            Mouse.move(ScreenObjects.MyRect)  # Move to center of rectangle
        """
        # Handle screen object parameter
        if y is None:
            # First parameter is a screen object
            if not hasattr(x_or_object, 'x') or not hasattr(x_or_object, 'y'):
                raise ValueError("Invalid parameter: expected coordinates (x, y) or a screen object with x, y attributes")
            
            if hasattr(x_or_object, 'is_point') and not x_or_object.is_point:
                # Rectangle object - move to center
                x1, y1 = x_or_object.x, x_or_object.y
                x2, y2 = x_or_object.x2, x_or_object.y2
                x = (x1 + x2) // 2
                y = (y1 + y2) // 2
            else:
                # Point object
                x = x_or_object.x
                y = x_or_object.y
        else:
            # Regular x, y coordinates
            x = x_or_object
        
        pyautogui.moveTo(x, y, duration=duration)
    
    @staticmethod
    def drag(x_or_object, y=None, duration: float = 0.5):
        """Drag mouse to coordinates or screen object
        
        Usage:
            Mouse.drag(100, 200)  # Drag to x=100, y=200
            Mouse.drag(ScreenObjects.MyPoint)  # Drag to point object
            Mouse.drag(ScreenObjects.MyRect)  # Drag to center of rectangle
        """
        # Handle screen object parameter
        if y is None:
            # First parameter is a screen object
            if not hasattr(x_or_object, 'x') or not hasattr(x_or_object, 'y'):
                raise ValueError("Invalid parameter: expected coordinates (x, y) or a screen object with x, y attributes")
            
            if hasattr(x_or_object, 'is_point') and not x_or_object.is_point:
                # Rectangle object - drag to center
                x1, y1 = x_or_object.x, x_or_object.y
                x2, y2 = x_or_object.x2, x_or_object.y2
                x = (x1 + x2) // 2
                y = (y1 + y2) // 2
            else:
                # Point object
                x = x_or_object.x
                y = x_or_object.y
        else:
            # Regular x, y coordinates
            x = x_or_object
        
        pyautogui.dragTo(x, y, duration=duration)
    
    @staticmethod
    def scroll(clicks: int):
        """Scroll mouse wheel"""
        pyautogui.scroll(clicks)

class Keyboard:
    """Keyboard control functions"""
    
    @staticmethod
    def write(text: str, interval: float = 0.0):
        """Type text with optional interval between characters
        
        Usage:
            Keyboard.write("Hello World")
            Keyboard.write("Slow typing", interval=0.1)
        """
        pyautogui.write(text, interval=interval)
    
    @staticmethod
    def press(key: str):
        """Press and release a single key
        
        Usage:
            Keyboard.press('enter')
            Keyboard.press('tab')
            Keyboard.press('esc')
        
        Common keys: enter, tab, esc, space, backspace, delete, 
                     up, down, left, right, home, end, pageup, pagedown,
                     f1-f12, shift, ctrl, alt, win
        """
        pyautogui.press(key)
    
    @staticmethod
    def hotkey(*keys):
        """Press a combination of keys (hold down multiple keys simultaneously)
        
        Usage:
            Keyboard.hotkey('ctrl', 'a')         # Select all
            Keyboard.hotkey('ctrl', 'c')         # Copy
            Keyboard.hotkey('ctrl', 'v')         # Paste
            Keyboard.hotkey('ctrl', 'shift', 's') # Save as
            Keyboard.hotkey('alt', 'tab')        # Switch window
            Keyboard.hotkey('win', 'd')          # Show desktop
        """
        pyautogui.hotkey(*keys)
    
    @staticmethod
    def hold(key: str):
        """Hold down a key (must call release() later)
        
        Usage:
            Keyboard.hold('shift')
            Keyboard.press('a')
            Keyboard.release('shift')
        """
        pyautogui.keyDown(key)
    
    @staticmethod
    def release(key: str):
        """Release a held key
        
        Usage:
            Keyboard.hold('ctrl')
            Keyboard.press('a')
            Keyboard.release('ctrl')
        """
        pyautogui.keyUp(key)
    
    @staticmethod
    def shortcut(*keys):
        """Alias for hotkey() - press a combination of keys
        
        Usage:
            Keyboard.shortcut('ctrl', 'a')  # Select all
        """
        pyautogui.hotkey(*keys)
    
    @staticmethod
    def combo(*keys):
        """Alias for hotkey() - press a combination of keys
        
        Usage:
            Keyboard.combo('ctrl', 'c')  # Copy
        """
        pyautogui.hotkey(*keys)

class Screen:
    """Screen capture and recognition functions"""
    
    @staticmethod
    def screenshot(region: Optional[Tuple[int, int, int, int]] = None) -> str:
        """Take a screenshot and return path"""
        import os
        import tempfile
        
        path = os.path.join(tempfile.gettempdir(), f'screenshot_{int(time.time())}.png')
        if region:
            screenshot = pyautogui.screenshot(region=region)
        else:
            screenshot = pyautogui.screenshot()
        screenshot.save(path)
        return path
    
    @staticmethod
    def locate_on_screen(image_path: str, confidence: float = 0.9) -> Optional[Tuple[int, int]]:
        """Find an image on screen"""
        try:
            location = pyautogui.locateOnScreen(image_path, confidence=confidence)
            if location:
                return (location.left + location.width // 2, location.top + location.height // 2)
            return None
        except:
            return None
    
    @staticmethod
    def ocr_region(x: int, y: int, width: int, height: int, language: str = 'en') -> str:
        """Extract text from a screen region using EasyOCR"""
        try:
            import easyocr
            import numpy as np
            import os
            
            print("\\n" + "="*70)
            print("[OCR] Starting OCR capture")
            print("[OCR] Input parameters:")
            print("  - Position: (" + str(x) + ", " + str(y) + ")")
            print("  - Size: " + str(width) + " x " + str(height))
            print("  - Bounding box: (" + str(x) + ", " + str(y) + ") to (" + str(x + width) + ", " + str(y + height) + ")")
            
            # Get screen info for verification
            try:
                import win32api
                screen_width = win32api.GetSystemMetrics(0)
                screen_height = win32api.GetSystemMetrics(1)
                print("[OCR] Screen size: " + str(screen_width) + " x " + str(screen_height))
                
                # Verify coordinates are within screen bounds
                if x < 0 or y < 0 or x + width > screen_width or y + height > screen_height:
                    print("[OCR WARNING] Coordinates are outside screen bounds!")
                    print("[OCR WARNING] This will likely capture wrong content.")
            except:
                pass
            
            # Use a persistent cache directory for the model
            model_storage_directory = os.path.join(os.path.expanduser('~'), '.wild_automation', 'easyocr_models')
            os.makedirs(model_storage_directory, exist_ok=True)
            
            # Create or reuse reader with cached model
            if not hasattr(Screen, '_ocr_reader') or not hasattr(Screen, '_ocr_language') or Screen._ocr_language != language:
                print("[OCR] Initializing EasyOCR reader for language: " + str(language))
                print("[OCR] Model cache directory: " + str(model_storage_directory))
                Screen._ocr_reader = easyocr.Reader([language], gpu=False, model_storage_directory=model_storage_directory)
                Screen._ocr_language = language
            
            # Take screenshot using PIL ImageGrab with EXACT coordinates
            # ImageGrab.grab() bbox format: (left, top, right, bottom) - SCREEN COORDINATES
            from PIL import ImageGrab
            
            left = x
            top = y
            right = x + width
            bottom = y + height
            
            print("[OCR] Capturing screenshot:")
            print("  - ImageGrab.grab(bbox=(" + str(left) + ", " + str(top) + ", " + str(right) + ", " + str(bottom) + "))")
            
            screenshot = ImageGrab.grab(bbox=(left, top, right, bottom), all_screens=False)
            
            actual_width, actual_height = screenshot.size
            print("[OCR] Screenshot captured:")
            print("  - Expected size: " + str(width) + " x " + str(height))
            print("  - Actual size: " + str(actual_width) + " x " + str(actual_height))
            
            if actual_width != width or actual_height != height:
                print("[OCR WARNING] Size mismatch detected!")
                print("[OCR WARNING] This indicates DPI scaling or coordinate system issue.")
                print("[OCR WARNING] Expected " + str(width) + "x" + str(height) + ", got " + str(actual_width) + "x" + str(actual_height))
            
            # Save screenshot for debugging
            debug_dir = os.path.join(os.path.expanduser('~'), '.wild_automation', 'ocr_debug')
            os.makedirs(debug_dir, exist_ok=True)
            timestamp = int(time.time())
            debug_path = os.path.join(debug_dir, 'ocr_' + str(timestamp) + '_x' + str(x) + '_y' + str(y) + '_w' + str(width) + '_h' + str(height) + '.png')
            screenshot.save(debug_path)
            print("[OCR] Debug screenshot saved:")
            print("  - Path: " + str(debug_path))
            print("  - Open this file to verify the captured region")
            
            # Perform OCR
            print("[OCR] Running EasyOCR text detection...")
            img_array = np.array(screenshot)
            results = Screen._ocr_reader.readtext(img_array)
            
            if results:
                print("[OCR] Found " + str(len(results)) + " text region(s)")
                text = ' '.join([result[1] for result in results])
            else:
                print("[OCR] No text detected in the region")
                text = ""
            
            # Handle encoding issues
            safe_text = text.replace('\u2588', '#')
            safe_text = safe_text.encode('ascii', 'replace').decode('ascii')
            
            print("[OCR] Extracted text (first 100 chars):")
            print("  - '" + safe_text[:100] + "'")
            print("="*70 + "\\n")
            
            return safe_text.strip()
            
        except ImportError as e:
            error_msg = "Missing dependency: " + str(e)
            print("[OCR ERROR] " + error_msg)
            return "Error: " + error_msg + ". Install with: pip install easyocr pillow pywin32"
        except Exception as e:
            error_msg = str(e).encode('ascii', 'replace').decode('ascii')
            print("[OCR ERROR] " + error_msg)
            import traceback
            traceback.print_exc()
            return "OCR Error: " + error_msg
    
    @staticmethod
    def ocr_object(screen_object, language: str = 'en') -> str:
        """Extract text from a screen object"""
        # screen_object is a ScreenObjects nested class with x, y, etc.
        if hasattr(screen_object, 'is_point') and screen_object.is_point:
            # Point object - can't OCR a point
            raise ValueError("Cannot perform OCR on point object '" + screen_object.name + "'. Use a rectangle object.")
        
        # Rectangle object - has x, y, x2, y2
        x1 = screen_object.x
        y1 = screen_object.y
        x2 = screen_object.x2
        y2 = screen_object.y2
        
        # Calculate bounding box (always use min/max for correct corners)
        left = min(x1, x2)
        top = min(y1, y2)
        right = max(x1, x2)
        bottom = max(y1, y2)
        width = right - left
        height = bottom - top
        
        print("\\n[OCR] Processing ScreenObject: " + str(screen_object.name))
        print("[OCR] Object coordinates: (" + str(x1) + ", " + str(y1) + ") to (" + str(x2) + ", " + str(y2) + ")")
        print("[OCR] Normalized to: (" + str(left) + ", " + str(top) + ") to (" + str(right) + ", " + str(bottom) + ")")
        print("[OCR] Dimensions: " + str(width) + " x " + str(height))
        
        return Screen.ocr_region(left, top, width, height, language)

class Utils:
    """Utility functions"""
    
    @staticmethod
    def wait(seconds: float):
        """Wait for specified seconds"""
        time.sleep(seconds)
    
    @staticmethod
    def log(message: str):
        """Log a message"""
        print(f"[LOG] {{message}}")
    
    @staticmethod
    def get_screen_size() -> Tuple[int, int]:
        """Get screen dimensions"""
        return pyautogui.size()
    
    @staticmethod
    def get_mouse_position() -> Tuple[int, int]:
        """Get current mouse position"""
        return pyautogui.position()

# Convenience aliases
wait = Utils.wait
log = Utils.log
''';
  }
}

