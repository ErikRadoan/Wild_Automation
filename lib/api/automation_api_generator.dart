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
    def focus(title: str) -> bool:
        """Focus a window by title (alias for activate)"""
        return Window.activate(title)
    
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

    @staticmethod
    def findText(screen_object: Tuple[int, int, int, int], text: str, language: str = 'en') -> Optional[Tuple[int, int]]:
        """Find text within a screen object and return its center position on screen

        Args:
            screen_object: Tuple of (x, y, width, height) representing the region to search
            text: The text to find
            language: Language code (default 'en')

        Returns:
            Tuple of (x, y) representing the center position of the found text on screen,
            or None if text not found
        """
        try:
            import easyocr
            import numpy as np

            x, y, width, height = screen_object

            # Initialize reader (cached after first use)
            if not hasattr(Screen, '_ocr_reader'):
                Screen._ocr_reader = easyocr.Reader([language], gpu=False)

            # Take screenshot of region
            screenshot = pyautogui.screenshot(region=(x, y, width, height))

            # Convert to numpy array
            img_array = np.array(screenshot)

            # Perform OCR with detailed results
            results = Screen._ocr_reader.readtext(img_array, detail=1)

            # Search for the text in results
            for detection in results:
                bbox, detected_text, confidence = detection

                # Check if detected text contains the search text (case-insensitive)
                if text.lower() in detected_text.lower():
                    # bbox is [[x1,y1], [x2,y2], [x3,y3], [x4,y4]]
                    # Calculate center of the bounding box
                    x_coords = [point[0] for point in bbox]
                    y_coords = [point[1] for point in bbox]
                    center_x = sum(x_coords) // len(x_coords)
                    center_y = sum(y_coords) // len(y_coords)

                    # Convert to screen coordinates by adding the object's position
                    screen_x = x + center_x
                    screen_y = y + center_y

                    return (screen_x, screen_y)

            return None
        except ImportError:
            print("Error: easyocr not installed. Run: pip install easyocr")
            return None
        except Exception as e:
            print(f"findText Error: {str(e)}")
            return None

class File:
    """File operations API"""

    @staticmethod
    def create(path: str, content: str = "") -> bool:
        """Create a new file with optional content

        Args:
            path: File path to create
            content: Optional initial content

        Returns:
            True if successful, False otherwise
        """
        try:
            import os
            # Create directory if it doesn't exist
            directory = os.path.dirname(path)
            if directory and not os.path.exists(directory):
                os.makedirs(directory)

            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"File.create Error: {str(e)}")
            return False

    @staticmethod
    def write(path: str, content: str) -> bool:
        """Write content to a file (overwrites existing content)

        Args:
            path: File path to write to
            content: Content to write

        Returns:
            True if successful, False otherwise
        """
        try:
            import os
            directory = os.path.dirname(path)
            if directory and not os.path.exists(directory):
                os.makedirs(directory)

            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"File.write Error: {str(e)}")
            return False

    @staticmethod
    def append(path: str, content: str) -> bool:
        """Append content to a file

        Args:
            path: File path to append to
            content: Content to append

        Returns:
            True if successful, False otherwise
        """
        try:
            import os
            directory = os.path.dirname(path)
            if directory and not os.path.exists(directory):
                os.makedirs(directory)

            with open(path, 'a', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"File.append Error: {str(e)}")
            return False

    @staticmethod
    def read(path: str) -> Optional[str]:
        """Read entire content of a file

        Args:
            path: File path to read from

        Returns:
            File content as string, or None if error
        """
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            print(f"File.read Error: {str(e)}")
            return None

    @staticmethod
    def read_lines(path: str) -> Optional[list]:
        """Read file content as list of lines

        Args:
            path: File path to read from

        Returns:
            List of lines, or None if error
        """
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return f.readlines()
        except Exception as e:
            print(f"File.read_lines Error: {str(e)}")
            return None

    @staticmethod
    def delete(path: str) -> bool:
        """Delete a file

        Args:
            path: File path to delete

        Returns:
            True if successful, False otherwise
        """
        try:
            import os
            if os.path.exists(path):
                os.remove(path)
                return True
            return False
        except Exception as e:
            print(f"File.delete Error: {str(e)}")
            return False

    @staticmethod
    def exists(path: str) -> bool:
        """Check if a file exists

        Args:
            path: File path to check

        Returns:
            True if file exists, False otherwise
        """
        try:
            import os
            return os.path.isfile(path)
        except:
            return False

    @staticmethod
    def copy(source: str, destination: str) -> bool:
        """Copy a file

        Args:
            source: Source file path
            destination: Destination file path

        Returns:
            True if successful, False otherwise
        """
        try:
            import shutil
            import os
            directory = os.path.dirname(destination)
            if directory and not os.path.exists(directory):
                os.makedirs(directory)
            shutil.copy2(source, destination)
            return True
        except Exception as e:
            print(f"File.copy Error: {str(e)}")
            return False

    @staticmethod
    def move(source: str, destination: str) -> bool:
        """Move/rename a file

        Args:
            source: Source file path
            destination: Destination file path

        Returns:
            True if successful, False otherwise
        """
        try:
            import shutil
            import os
            directory = os.path.dirname(destination)
            if directory and not os.path.exists(directory):
                os.makedirs(directory)
            shutil.move(source, destination)
            return True
        except Exception as e:
            print(f"File.move Error: {str(e)}")
            return False

    @staticmethod
    def get_size(path: str) -> Optional[int]:
        """Get file size in bytes

        Args:
            path: File path

        Returns:
            File size in bytes, or None if error
        """
        try:
            import os
            return os.path.getsize(path)
        except Exception as e:
            print(f"File.get_size Error: {str(e)}")
            return None

    @staticmethod
    def list_directory(path: str) -> Optional[list]:
        """List all files and directories in a directory

        Args:
            path: Directory path

        Returns:
            List of file/directory names, or None if error
        """
        try:
            import os
            return os.listdir(path)
        except Exception as e:
            print(f"File.list_directory Error: {str(e)}")
            return None

    @staticmethod
    def create_directory(path: str) -> bool:
        """Create a directory (including parent directories)

        Args:
            path: Directory path to create

        Returns:
            True if successful, False otherwise
        """
        try:
            import os
            os.makedirs(path, exist_ok=True)
            return True
        except Exception as e:
            print(f"File.create_directory Error: {str(e)}")
            return False

    @staticmethod
    def delete_directory(path: str) -> bool:
        """Delete a directory and all its contents

        Args:
            path: Directory path to delete

        Returns:
            True if successful, False otherwise
        """
        try:
            import shutil
            import os
            if os.path.exists(path):
                shutil.rmtree(path)
                return True
            return False
        except Exception as e:
            print(f"File.delete_directory Error: {str(e)}")
            return False

    @staticmethod
    def get_absolute_path(path: str) -> str:
        """Get absolute path from relative path

        Args:
            path: Relative or absolute path

        Returns:
            Absolute path
        """
        try:
            import os
            return os.path.abspath(path)
        except:
            return path

    @staticmethod
    def join_path(*paths) -> str:
        """Join path components

        Args:
            *paths: Path components to join

        Returns:
            Joined path
        """
        import os
        return os.path.join(*paths)

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

