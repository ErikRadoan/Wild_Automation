/// Automation API generator for Python scripts
/// This generates Python code that can be imported in user scripts
class AutomationAPIGenerator {
  /// Generate the Python API library code
  static String generatePythonAPI({
    required Map<String, dynamic> screenObjects,
    required Map<String, dynamic> windowTargets,
  }) {
    return '''
import pyautogui
import time
import subprocess
import sys
from typing import Tuple, Optional

# Wild Automation API
# Auto-generated - DO NOT MODIFY

class ScreenObjects:
    """Access to defined screen objects"""
    
${_generateScreenObjectsCode(screenObjects)}

class Windows:
    """Window manipulation functions"""
    
${_generateWindowsCode(windowTargets)}
    
    @staticmethod
    def focus(window_name: str) -> bool:
        """Focus a window by name"""
        try:
            # Windows-specific implementation
            import win32gui
            import win32con
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    title = win32gui.GetWindowText(hwnd)
                    if window_name.lower() in title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            
            if windows:
                hwnd = windows[0]
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                win32gui.SetForegroundWindow(hwnd)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def launch(executable_path: str) -> bool:
        """Launch an application"""
        try:
            subprocess.Popen(executable_path)
            return True
        except:
            return False

class Window:
    """Window control functions (alternative to Windows class)"""
    
    @staticmethod
    def activate(title: str) -> bool:
        """Activate/focus a window by title"""
        try:
            import win32gui
            import win32con
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    if title.lower() in window_title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            
            if windows:
                hwnd = windows[0]
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                win32gui.SetForegroundWindow(hwnd)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def maximize(title: str) -> bool:
        """Maximize a window by title"""
        try:
            import win32gui
            import win32con
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    if title.lower() in window_title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            
            if windows:
                hwnd = windows[0]
                win32gui.ShowWindow(hwnd, win32con.SW_MAXIMIZE)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def minimize(title: str) -> bool:
        """Minimize a window by title"""
        try:
            import win32gui
            import win32con
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    if title.lower() in window_title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            
            if windows:
                hwnd = windows[0]
                win32gui.ShowWindow(hwnd, win32con.SW_MINIMIZE)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def restore(title: str) -> bool:
        """Restore a window by title"""
        try:
            import win32gui
            import win32con
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    if title.lower() in window_title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            
            if windows:
                hwnd = windows[0]
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                return True
            return False
        except:
            return False
    
    @staticmethod
    def close(title: str) -> bool:
        """Close a window by title"""
        try:
            import win32gui
            import win32con
            
            def callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    if title.lower() in window_title.lower():
                        windows.append(hwnd)
                return True
            
            windows = []
            win32gui.EnumWindows(callback, windows)
            
            if windows:
                hwnd = windows[0]
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
    def exists(title: str) -> bool:
        """Check if window exists"""
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
            return len(windows) > 0
        except:
            return False


class Mouse:
    """Mouse control functions"""
    
    @staticmethod
    def click(x: int, y: int, button: str = 'left', clicks: int = 1):
        """Click at coordinates"""
        pyautogui.click(x, y, button=button, clicks=clicks)
    
    @staticmethod
    def move(x: int, y: int, duration: float = 0.0):
        """Move mouse to coordinates"""
        pyautogui.moveTo(x, y, duration=duration)
    
    @staticmethod
    def drag(x: int, y: int, duration: float = 0.5):
        """Drag mouse to coordinates"""
        pyautogui.dragTo(x, y, duration=duration)
    
    @staticmethod
    def scroll(clicks: int):
        """Scroll mouse wheel"""
        pyautogui.scroll(clicks)

class Keyboard:
    """Keyboard control functions"""
    
    @staticmethod
    def write(text: str, interval: float = 0.0):
        """Type text"""
        pyautogui.write(text, interval=interval)
    
    @staticmethod
    def press(key: str):
        """Press a key"""
        pyautogui.press(key)
    
    @staticmethod
    def hotkey(*keys):
        """Press a combination of keys"""
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
        """Extract text from a screen region using EasyOCR

        Args:
            x: X coordinate of top-left corner
            y: Y coordinate of top-left corner
            width: Width of region
            height: Height of region
            language: Language code (default 'en', supports multiple like 'en,es')

        Returns:
            Extracted text from the region
        """
        try:
            import easyocr

            # Initialize reader (cached after first use)
            if not hasattr(Screen, '_ocr_reader'):
                Screen._ocr_reader = easyocr.Reader([language], gpu=False)

            # Take screenshot of region
            screenshot = pyautogui.screenshot(region=(x, y, width, height))
            
            # Convert to numpy array
            import numpy as np
            img_array = np.array(screenshot)

            # Perform OCR
            results = Screen._ocr_reader.readtext(img_array)

            # Combine all text
            text = ' '.join([result[1] for result in results])
            return text.strip()
        except ImportError:
            return "Error: easyocr not installed. Run: pip install easyocr"
        except Exception as e:
            return f"OCR Error: {str(e)}"
    
    @staticmethod
    def ocr_object(screen_object: Tuple[int, int, int, int], language: str = 'en') -> str:
        """Extract text from a screen object (rectangle)
        
        Args:
            screen_object: Tuple of (x, y, width, height) or (x1, y1, x2, y2)
            language: Language code (default 'en')

        Returns:
            Extracted text from the region
        """
        x, y, width, height = screen_object
        return Screen.ocr_region(x, y, width, height, language)

class Utils:
    """Utility functions"""
    
    @staticmethod
    def wait(seconds: float):
        """Wait for specified seconds"""
        time.sleep(seconds)
    
    @staticmethod
    def log(message: str):
        """Log a message"""
        print(f"[LOG] {message}")
    
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

  static String _generateScreenObjectsCode(Map<String, dynamic> screenObjects) {
    final buffer = StringBuffer();

    for (final entry in screenObjects.entries) {
      final name = entry.key;
      final obj = entry.value;

      if (obj['type'] == 'point') {
        buffer.writeln('    $name = (${obj['x']}, ${obj['y']})  # Point: ${obj['description'] ?? ''}');
      } else {
        buffer.writeln('    $name = (${obj['x']}, ${obj['y']}, ${obj['width']}, ${obj['height']})  # Rectangle: ${obj['description'] ?? ''}');
      }
    }

    if (screenObjects.isEmpty) {
      buffer.writeln('    pass  # No screen objects defined');
    }

    return buffer.toString();
  }

  static String _generateWindowsCode(Map<String, dynamic> windowTargets) {
    final buffer = StringBuffer();

    for (final entry in windowTargets.entries) {
      final name = entry.key;
      final target = entry.value;

      buffer.writeln('    $name = "${target['windowTitle'] ?? target['processName'] ?? ''}"  # ${target['description'] ?? ''}');
    }

    if (windowTargets.isEmpty) {
      buffer.writeln('    pass  # No window targets defined');
    }

    return buffer.toString();
  }

  /// Generate requirements.txt for Python dependencies
  static String generateRequirements() {
    return '''
pyautogui>=0.9.53
pywin32>=305
pillow>=9.0.0
easyocr>=1.7.0
numpy>=1.21.0
''';
  }

  /// Generate installation instructions
  static String generateInstallInstructions() {
    return '''
# Python Setup Instructions for Wild Automation

## Prerequisites
1. Python 3.7 or higher must be installed
2. pip must be available

## Installation
Run the following command to install required packages:

pip install pyautogui pywin32 pillow

Or use the requirements.txt file:

pip install -r requirements.txt

## Verification
Test your installation:

python -c "import pyautogui; print('PyAutoGUI version:', pyautogui.__version__)"

## Troubleshooting
- If pywin32 fails to install, try: pip install pywin32 --upgrade
- On some systems you may need to use python3 and pip3 instead
- Make sure Python is added to your system PATH
''';
  }
}

