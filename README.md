<div align="center">
  <img src="assets/wild_automate_logo.png" alt="WILD Automate Logo" width="200"/>
  
  # WILD Automate
  
  **UI Automation Made Simple**
  
  *Powerful desktop automation for Windows*
  
  [![License](https://img.shields.io/badge/license-Proprietary-blue.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/windows)
  [![Python](https://img.shields.io/badge/python-3.7+-green.svg)](https://www.python.org/)
  
</div>

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [User Guide](#user-guide)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)

---

## 🎯 Overview

**WILD Automate** is a professional desktop automation tool that empowers you to automate repetitive tasks on Windows. Whether you're automating data entry, testing applications, or creating complex workflows, WILD Automate provides an intuitive interface and powerful Python-based scripting engine to get the job done.

### Why WILD Automate?

- ✨ **User-Friendly Interface** - No coding experience required to get started
- 🎯 **Visual Object Management** - Point-and-click coordinate selection
- 🐍 **Python-Powered** - Flexible scripting with full Python support
- 🔄 **Project-Based** - Organize your automations into projects
- 🌍 **Multi-Language** - English and German support
- 🎨 **Modern UI** - Clean, professional interface with light and dark themes
- 📊 **Real-Time Feedback** - Monitor execution with live logs and output tracking

---

## ✨ Features

### 📍 Screen Object Management
- **Visual Coordinate Picker**: Click anywhere on your screen to capture coordinates
- **Point Objects**: Store single coordinates for clicks and references
- **Rectangle Objects**: Define screen regions for OCR, screenshots, and more
- **Live Preview**: Visualize all your objects overlaid on your screen
- **Easy Organization**: Name and manage objects for quick reference in scripts

### 🔄 Automation Flows
- **Python Scripting**: Write automation logic using Python
- **Smart Code Editor**: Syntax highlighting, auto-completion, and error detection
- **Variable Detection**: Automatically identify input and output variables
- **API Integration**: Use built-in WILD API for mouse, keyboard, window, and OCR operations
- **Flow Management**: Create, edit, and organize multiple automation flows per project

### ▶️ Execution Engine
- **Flexible Inputs**: Configure input variables before each execution
- **Output Tracking**: Monitor selected variables in real-time
- **Live Console**: View execution logs as they happen
- **Error Handling**: Detailed error messages and stack traces
- **Async Support**: Built-in delays and waiting functions

### 🖥️ Window Management
- **Focus Windows**: Automatically bring target windows to the foreground
- **Launch Applications**: Start programs as part of your automation
- **Window Waiting**: Pause until windows become available

### 🔍 OCR (Text Recognition)
- **EasyOCR Integration**: Extract text from screen regions
- **Multi-Language Support**: Recognize text in multiple languages
- **Screenshot Capture**: Automatic region screenshots for verification

### 🎨 Keyboard & Mouse Control
- **Mouse Operations**: Click, move, drag, and scroll
- **Keyboard Input**: Type text and send key combinations
- **Hotkeys**: Send Ctrl+C, Alt+F4, and other keyboard shortcuts
- **Precise Control**: Pixel-perfect coordinate control

---

## 💾 Installation

### Step 1: Download WILD Automate

1. Download the latest release from the [Releases page](https://github.com/your-org/wild_automation/releases)
2. Extract the ZIP file to a location of your choice (e.g., `C:\Program Files\WILD Automate`)

### Step 2: Install Python

WILD Automate requires Python to run automation scripts.

1. Download Python from [python.org/downloads](https://www.python.org/downloads/)
2. **Important**: During installation, check ☑️ **"Add Python to PATH"**
3. Complete the installation

### Step 3: Launch WILD Automate

1. Navigate to the extracted folder
2. Run `wild_automation.exe`
3. On first launch, you'll see the **Project Selection** screen

### Step 4: Install Python Dependencies

1. Click the **Settings** icon (gear icon) on the project selection screen
2. Navigate to the **Dependencies** tab
3. Review the list of required Python packages
4. Click **"Install Missing Dependencies"**
5. Wait for the installation to complete

**Required Dependencies:**
- `pyautogui` - Mouse and keyboard automation
- `pywin32` - Windows API integration
- `pillow` - Image processing
- `easyocr` - Optical character recognition
- `opencv-python` - Computer vision

✅ Once installation is complete, you're ready to create your first project!

---

## 🚀 Quick Start

### Create Your First Project

1. **Launch WILD Automate**
2. On the project selection screen, click **"New Project"**
3. Enter a project name (e.g., "My First Automation")
4. Optionally add a description
5. Click **"Create"**

### Create a Screen Object

1. Navigate to the **Objects** tab
2. Click **"New Object"**
3. Enter a name (e.g., "StartButton")
4. Choose **Point** or **Rectangle**
5. Click **"Pick Coordinate"** - your screen will darken
6. Click on the desired location
7. For rectangles, click a second time to define the region
8. Click **"Save"**

💡 **Tip**: Use the **Preview** button to see all your objects overlaid on the screen!

### Write Your First Flow

1. Navigate to the **Flow** tab
2. Click the **"+"** button
3. Enter a flow name and description
4. Write your automation script:

```python
# Example: Click the Start button and type "notepad"
from wild_api import Mouse, Keyboard, Window, Utils

# Focus on the desktop
Window.focus("Desktop")

# Click the start button object we created
start_x, start_y = ScreenObjects.StartButton
Mouse.click(start_x, start_y)

# Wait for start menu to open
Utils.wait(0.5)

# Type "notepad"
Keyboard.write("notepad")

# Press Enter
Keyboard.press("enter")

Utils.log("Notepad launched successfully!")
```

5. Click **"Save"**

### Execute Your Flow

1. Navigate to the **Execute** tab
2. Select your flow from the dropdown
3. If you have input variables, configure them
4. Select output variables you want to track
5. Click **"Execute Flow"**
6. Watch the magic happen! ✨

---

## 📚 User Guide

### Projects

Projects help you organize related automation tasks.

- **Create**: Click "New Project" on the launch screen
- **Open**: Click on a recent project or use "Open Project"
- **Switch**: Use the arrow button at the bottom of the left sidebar to return to project selection

### Objects Tab

**Screen objects** are reusable coordinate references.

#### Point Objects
- Store a single coordinate (x, y)
- Perfect for buttons, icons, and click targets
- Reference in code: `x, y = ScreenObjects.MyPoint`

#### Rectangle Objects
- Store two coordinates defining a region (x1, y1, x2, y2)
- Perfect for OCR, screenshots, and drag operations
- Reference in code: `x1, y1, x2, y2 = ScreenObjects.MyRectangle`

#### Visual Coordinate Picker
1. Click "Pick Coordinate"
2. Your screen darkens with a transparent overlay
3. Click to capture coordinates
4. For rectangles, the first point is shown as you select the second

#### Live Preview
- Click **"Preview Objects"** to see all objects
- Each object is drawn with its name
- Objects are color-coded for easy identification

### Flow Tab

**Flows** contain your automation Python scripts.

#### Code Editor Features
- **Syntax Highlighting**: Python code is colorized
- **Auto-Completion**: Start typing API functions for suggestions
- **API Reference**: Click "API Reference" to view all available functions
- **Error Detection**: Syntax errors are highlighted in real-time

#### Variable Detection
WILD Automate automatically detects variables:
- **Input Variables**: Variables assigned at the start (can be configured)
- **Output Variables**: Variables you want to track during execution

### Execute Tab

Run your automation flows with full control.

1. **Select Flow**: Choose which flow to execute
2. **Configure Inputs**: Set values for input variables
3. **Select Outputs**: Choose which variables to track
4. **Execute**: Click to start
5. **Monitor**: View live logs and output values

#### Execution Console
- Real-time log output
- Error messages and stack traces
- Copyable text for debugging
- Auto-scrolls to latest output

### Settings

#### Themes
- **Light Theme**: Professional white interface
- **Dark Theme**: Easy on the eyes for long sessions
- Switch anytime without restarting

#### Languages
- **English**: Full interface translation
- **German (Deutsch)**: Vollständige Übersetzung
- More languages coming soon!

#### Dependencies
- View all required Python packages
- See which are installed vs. missing
- One-click installation of missing packages
- Includes EasyOCR models for text recognition

---

## 🔧 API Reference

### Mouse Control

```python
from wild_api import Mouse

# Click at coordinates
Mouse.click(x, y, button='left', clicks=1)

# Right-click
Mouse.click(x, y, button='right')

# Double-click
Mouse.click(x, y, clicks=2)

# Move mouse
Mouse.move(x, y, duration=0.5)

# Drag
Mouse.drag(to_x, to_y, duration=0.5)

# Scroll
Mouse.scroll(clicks=3)  # Positive = up, negative = down
```

### Keyboard Control

```python
from wild_api import Keyboard

# Type text
Keyboard.write("Hello World", interval=0.05)

# Press a single key
Keyboard.press("enter")
Keyboard.press("tab")
Keyboard.press("esc")

# Send key combinations (hotkeys)
Keyboard.hotkey("ctrl", "c")      # Copy
Keyboard.hotkey("ctrl", "v")      # Paste
Keyboard.hotkey("ctrl", "a")      # Select all
Keyboard.hotkey("alt", "f4")      # Close window
Keyboard.hotkey("win", "r")       # Run dialog
```

### Window Management

```python
from wild_api import Window

# Focus a window by title
Window.focus("Notepad")
Window.focus("Google Chrome")

# Activate a window (bring to foreground and wait)
Window.activate("Calculator")

# Maximize a window
Window.maximize("Microsoft Word")

# Minimize a window
Window.minimize("Task Manager")

# Close a window
Window.close("Untitled - Notepad")
```

### Screen Operations

```python
from wild_api import Screen

# OCR: Extract text from a screen region
text = Screen.ocr_object(ScreenObjects.MyRectangle, language="en")

# You can also use multiple languages
text = Screen.ocr_object(ScreenObjects.MyRectangle, language=["en", "de"])

# Take screenshot of entire screen
path = Screen.screenshot()

# Take screenshot of a specific region
path = Screen.screenshot_region(x1, y1, x2, y2)
```

### Screen Objects

Access objects you've created in the Objects tab:

```python
from wild_api import ScreenObjects

# Point object (single coordinate)
x, y = ScreenObjects.MyButton
Mouse.click(x, y)

# Rectangle object (two coordinates)
x1, y1, x2, y2 = ScreenObjects.MyTextArea
text = Screen.ocr_object(ScreenObjects.MyTextArea, language="en")
```

### Utilities

```python
from wild_api import Utils

# Wait (pause execution)
Utils.wait(1.5)  # Wait 1.5 seconds

# Log messages (appears in execution console)
Utils.log("Starting automation...")
Utils.log(f"Result: {result}")

# Get screen dimensions
width, height = Utils.get_screen_size()

# Get current mouse position
x, y = Utils.get_mouse_position()
Utils.log(f"Mouse is at ({x}, {y})")
```

### Example Flow

Here's a complete example that demonstrates multiple features:

```python
from wild_api import Mouse, Keyboard, Window, Screen, Utils, ScreenObjects

# Input variables (configurable in Execute tab)
search_query = "WILD Automate"
language = "en"

# Focus on browser
Utils.log("Focusing browser...")
Window.activate("Google Chrome")
Utils.wait(0.5)

# Click search bar
search_x, search_y = ScreenObjects.SearchBar
Mouse.click(search_x, search_y)
Utils.wait(0.3)

# Type search query
Utils.log(f"Searching for: {search_query}")
Keyboard.write(search_query)
Utils.wait(0.2)

# Press Enter
Keyboard.press("enter")
Utils.wait(2)

# Extract text from results area
Utils.log("Reading search results...")
results_text = Screen.ocr_object(ScreenObjects.ResultsArea, language=language)

# Output variables (tracked in Execute tab)
result_count = len(results_text.split('\n'))
status = "Success"

Utils.log(f"Found {result_count} lines of text")
Utils.log("Automation complete!")
```

---

## 🔧 Troubleshooting

### Python Not Found

**Symptoms:**
- Error: "Python is not installed or not in PATH"
- Dependencies won't install

**Solution:**
1. Download Python from [python.org](https://www.python.org/downloads/)
2. During installation, **check** ☑️ "Add Python to PATH"
3. Restart WILD Automate
4. Verify installation by opening CMD and typing: `python --version`

### Missing Dependencies

**Symptoms:**
- ⚠️ Warning icon in project selection
- Projects are disabled
- Execution fails with "ModuleNotFoundError"

**Solution:**
1. Open WILD Automate
2. Click **Settings** (gear icon)
3. Navigate to **Dependencies** tab
4. Click **"Install Missing Dependencies"**
5. Wait for installation to complete (may take 2-5 minutes for EasyOCR)
6. Restart the application

### EasyOCR Model Download

**Note:** The first time you use OCR, EasyOCR will download language models (~100MB for English). This is automatic but requires an internet connection.

**If download fails:**
- Check your internet connection
- Disable antivirus temporarily
- Run WILD Automate as Administrator

### Coordinate Picker Not Working

**Symptoms:**
- Screen doesn't darken when clicking "Pick Coordinate"
- Can't click to select coordinates

**Solution:**
1. Make sure WILD Automate has focus
2. Try clicking "Pick Coordinate" again
3. Check Windows display scaling (100% recommended)
4. Run as Administrator if on high-security system

### Automation Doesn't Work

**Common Issues:**

1. **Target window not focused**
   - Use `Window.activate()` to ensure window is ready
   - Add `Utils.wait()` after focusing windows

2. **Timing issues**
   - Add delays between actions: `Utils.wait(0.5)`
   - Increase wait times for slow applications

3. **Coordinates are off**
   - Re-capture coordinates using coordinate picker
   - Check if display scaling is enabled (may affect coordinates)
   - Verify monitor resolution hasn't changed

4. **Keyboard/Mouse not working**
   - Run WILD Automate as Administrator
   - Check that target application isn't running as Administrator
   - Disable "Filter Keys" in Windows accessibility settings

### OCR Returns Wrong Text

**Tips for Better OCR:**
- Use high-contrast areas (dark text on light background)
- Ensure text is clearly visible (not blurred or too small)
- Use appropriate language parameter
- Capture larger regions (OCR works better with more context)

### Application Crashes

**Steps:**
1. Check the console for error messages
2. Verify all Python dependencies are installed
3. Try creating a new project
4. Report the issue with error details

---

## ❓ FAQ

### Is WILD Automate free?

WILD Automate is developed by the WILD group. Please refer to the license for usage terms.

### What Windows versions are supported?

WILD Automate works on Windows 10 and Windows 11 (64-bit).

### Can I automate applications in the background?

Currently, WILD Automate requires windows to be visible and focused. Background automation is planned for future releases.

### How do I backup my projects?

Projects are stored in your Documents folder under `WILD Projects\`. Simply copy the project folder to back up all objects, flows, and settings.

### Can I share flows with others?

Yes! Simply share your project folder. The recipient needs to have WILD Automate and the required Python dependencies installed.

### Is my data sent to the cloud?

No. All data is stored locally on your computer. WILD Automate does not send any data to external servers (except for downloading Python packages and OCR models).

### Can I use custom Python libraries?

Yes! You can import any Python library installed in your Python environment. Just use normal Python `import` statements.

### How precise are the coordinates?

Coordinates are pixel-perfect. However, display scaling and multi-monitor setups may affect accuracy. We recommend using 100% display scaling for best results.

### Can I schedule flows to run automatically?

Scheduled execution is planned for a future release. Currently, you must manually execute flows.

### Does it work with games?

WILD Automate can interact with many games, but some games with anti-cheat systems may block automation. Always respect game terms of service.

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Windows 10 (64-bit) or later
- **RAM**: 4 GB
- **Storage**: 500 MB free space
- **Display**: 1280x720 resolution
- **Python**: 3.7 or higher

### Recommended Requirements
- **OS**: Windows 11 (64-bit)
- **RAM**: 8 GB or more
- **Storage**: 2 GB free space (for OCR models)
- **Display**: 1920x1080 resolution
- **Python**: 3.10 or higher
- **Internet**: For downloading dependencies and OCR models

---

## 🛡️ Security & Privacy

- **Local Storage**: All data is stored locally on your computer
- **No Telemetry**: WILD Automate does not collect usage data
- **Open Dependencies**: All Python packages are open-source and well-established
- **No Account Required**: No registration or login needed

**Important**: Automation scripts have full access to your system. Only run flows you trust and understand.

---

## 🔄 Updates

WILD Automate will notify you when updates are available. Updates include:
- New features
- Bug fixes
- Performance improvements
- Security patches

To update:
1. Download the latest version
2. Extract to the same location (overwrite old files)
3. Your projects and data are preserved

---

## 📞 Support

Need help? Here's how to get support:

### Documentation
- This README covers most use cases
- Check the API Reference section for coding help
- Review the Troubleshooting section for common issues

### Community
- Join our Discord server (coming soon)
- Browse GitHub Discussions
- Check existing GitHub Issues

### Bug Reports
Found a bug? Please report it!
1. Go to [GitHub Issues](https://github.com/your-org/wild_automation/issues)
2. Check if it's already reported
3. Create a new issue with:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots if applicable
   - Error messages from console

### Feature Requests
Have an idea? We'd love to hear it!
1. Open a GitHub Discussion
2. Describe your feature idea
3. Explain the use case
4. Community can vote and discuss

---

## 🗺️ Roadmap

Upcoming features we're working on:

### Version 1.1
- [ ] Scheduled flow execution
- [ ] Flow templates library
- [ ] Export/import flows
- [ ] Multiple language improvements

### Version 1.2
- [ ] Visual flow builder (drag-and-drop)
- [ ] Conditional logic (if/else blocks)
- [ ] Loop constructs (for/while)
- [ ] Better error messages

### Version 2.0
- [ ] Plugin system
- [ ] Custom action library
- [ ] Flow debugging with breakpoints
- [ ] Multi-monitor support improvements
- [ ] Image recognition and template matching
- [ ] Macro recording

---

## 📄 License

Copyright © 2024 WILD Group. All rights reserved.

This software is proprietary. Redistribution and modification are not permitted without explicit permission from the WILD Group.

---

## 🙏 Acknowledgments

WILD Automate is built with amazing open-source technologies:

- **Flutter** - UI framework
- **Python** - Automation runtime
- **PyAutoGUI** - Mouse and keyboard control
- **EasyOCR** - Text recognition
- **PyWin32** - Windows integration

Special thanks to all contributors and the open-source community!

---

## 📧 Contact

**WILD Group**

- 🌐 Website: Coming soon
- 📧 Email: support@wildgroup.example
- 💬 Discord: Coming soon
- 🐦 Twitter: @WILDGroup (coming soon)

---

<div align="center">
  
  **WILD Automate** - *Automate Anything, Anywhere*
  
  Made with ❤️ by the WILD Group
  
  [Download](https://github.com/your-org/wild_automation/releases) • [Documentation](#) • [Report Bug](https://github.com/your-org/wild_automation/issues) • [Request Feature](https://github.com/your-org/wild_automation/issues)
  
</div>

