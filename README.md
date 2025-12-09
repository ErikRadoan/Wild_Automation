# Wild Automation

A powerful desktop UI automation application developed by the WILD group. Built with Flutter and Python, this app provides a comprehensive object-oriented solution for creating, managing, and executing automation flows.

## Features

### 🎯 Screen Object Management
- Define **points** and **rectangles** on your screen
- Store and reference screen coordinates for later use
- Easy-to-use visual object management interface
- Objects can be referenced in Python automation scripts

### 💻 Flow Creation
- Write automation logic in Python with custom API
- Built-in code editor with syntax support
- Automatic variable detection using static code analysis
- Save and manage multiple automation flows

### ▶️ Flow Execution
- Configure input variables with custom values
- Select output variables to track during execution
- Real-time log streaming during execution
- Comprehensive execution results and error reporting
- Asynchronous Python execution with delay support

## Architecture

The application follows a clean **Object-Oriented Programming (OOP)** architecture with clear separation of concerns:

```
lib/
├── models/              # Domain models (entities)
│   ├── screen_object.dart
│   ├── window_target.dart
│   ├── flow.dart
│   ├── flow_variable.dart
│   └── execution_result.dart
├── services/            # Business logic services
│   ├── storage_service.dart
│   ├── code_analyzer_service.dart
│   └── python_execution_service.dart
├── providers/           # State management (Provider pattern)
│   ├── object_provider.dart
│   ├── flow_provider.dart
│   └── execution_provider.dart
├── screens/             # UI screens
│   ├── objects_screen.dart
│   ├── flow_screen.dart
│   └── execute_screen.dart
├── widgets/             # Reusable UI components
│   ├── object_form_dialog.dart
│   ├── flow_form_dialog.dart
│   └── code_editor_widget.dart
├── api/                 # Python API generation
│   └── automation_api_generator.dart
└── main.dart           # Application entry point
```

### Key Components

#### Models (Domain Layer)
- **ScreenObject**: Represents a point or rectangle on the screen
- **WindowTarget**: Represents a target application window
- **Flow**: Contains Python code and metadata
- **FlowVariable**: Represents input/output variables
- **ExecutionResult**: Tracks execution status and results

#### Services (Business Logic Layer)
- **StorageService**: Hive-based persistence (key-value storage)
- **CodeAnalyzerService**: Static analysis of Python code to extract variables
- **PythonExecutionService**: Executes Python scripts with I/O handling

#### Providers (State Management Layer)
- **ObjectProvider**: Manages screen objects (CRUD operations)
- **FlowProvider**: Manages flows and code analysis
- **ExecutionProvider**: Handles flow execution and I/O configuration

## Getting Started

### Prerequisites

1. **Flutter SDK** (3.9.2 or higher)
   - Install from: https://flutter.dev/docs/get-started/install
   
2. **Python** (3.7 or higher)
   - Install from: https://python.org/downloads
   - Make sure Python is added to your system PATH

3. **Python Dependencies**
   ```bash
   pip install pyautogui pywin32 pillow
   ```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/wild_automation.git
   cd wild_automation
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Hive adapters:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the application:
   ```bash
   flutter run -d windows
   ```

## Usage Guide

### 1. Creating Screen Objects

1. Navigate to the **Objects** tab
2. Click the **"New Object"** button
3. Choose object type:
   - **Point**: A single coordinate (x, y)
   - **Rectangle**: An area defined by (x, y, width, height)
4. Enter the coordinates and a descriptive name
5. Save the object

**Tips:**
- Use descriptive names (e.g., `LoginButton`, `SearchBox`)
- Names must be valid Python identifiers
- Objects can be referenced in your automation scripts

### 2. Writing Automation Flows

1. Navigate to the **Flow** tab
2. Click the **"+"** button to create a new flow
3. Write your Python automation code in the editor
4. Use the Wild Automation API in your code:

```python
from wild_api import Mouse, Keyboard, Screen, Utils

# Click at a defined object
Mouse.click(100, 200)

# Wait for 1 second
Utils.wait(1)

# Type some text
Keyboard.write("Hello World")

# Take a screenshot
screenshot_path = Screen.screenshot()
Utils.log(f"Screenshot saved to: {screenshot_path}")

# Your variables
username = "test_user"
result = "Success"
```

5. Save the flow

### 3. Executing Flows

1. Select a flow from the **Flow** tab
2. Navigate to the **Execute** tab
3. Configure inputs:
   - View detected input variables
   - Enter values for each input variable
4. Select output variables to track
5. Click **"Execute Flow"**
6. Monitor:
   - Execution status (Running/Completed/Failed)
   - Real-time logs
   - Output variable values
   - Execution duration

## Python API Reference

### Mouse Control
```python
from wild_api import Mouse

# Click at coordinates
Mouse.click(x, y, button='left', clicks=1)

# Move mouse
Mouse.move(x, y, duration=0.0)

# Drag to coordinates
Mouse.drag(x, y, duration=0.5)

# Scroll
Mouse.scroll(clicks)
```

### Keyboard Control
```python
from wild_api import Keyboard

# Type text
Keyboard.write("Hello World", interval=0.0)

# Press a key
Keyboard.press("enter")

# Hotkey combination
Keyboard.hotkey("ctrl", "c")
```

### Screen Operations
```python
from wild_api import Screen

# Take screenshot
path = Screen.screenshot()
path = Screen.screenshot(region=(x, y, width, height))

# Find image on screen
location = Screen.locate_on_screen("button.png", confidence=0.9)
```

### Window Management
```python
from wild_api import Windows

# Focus a window
Windows.focus("Notepad")

# Launch application
Windows.launch("C:\\Program Files\\App\\app.exe")
```

### Utilities
```python
from wild_api import Utils

# Wait
Utils.wait(2.5)  # Wait 2.5 seconds

# Log message
Utils.log("Processing complete")

# Get screen size
width, height = Utils.get_screen_size()

# Get mouse position
x, y = Utils.get_mouse_position()
```

### Screen Objects
Access your defined objects:
```python
from wild_api import ScreenObjects

# If you defined "LoginButton" as a point at (100, 200)
x, y = ScreenObjects.LoginButton
Mouse.click(x, y)

# If you defined "SearchArea" as a rectangle
x, y, width, height = ScreenObjects.SearchArea
```

## Variable Detection

The app automatically detects variables in your Python code:

### Input Variables
Variables assigned early in the code are detected as inputs:
```python
username = "default_user"  # Detected as input
password = "default_pass"  # Detected as input

# Your automation logic here
```

### Output Variables
Variables used after assignment are detected as outputs:
```python
result = perform_automation()  # Can be tracked as output
status = "completed"           # Can be tracked as output
```

You can configure which variables to use as inputs/outputs in the Execute tab.

## Data Persistence

All data is stored locally using **Hive** (NoSQL database):
- Screen objects are persisted automatically
- Flows are saved with their code
- Data is stored in the application's local directory
- No cloud storage or network required

## Troubleshooting

### Python Not Found
**Error:** "Python is not installed or not found in PATH"

**Solution:**
1. Install Python from python.org
2. Make sure "Add Python to PATH" is checked during installation
3. Verify: `python --version` or `python3 --version`

### PyAutoGUI Import Error
**Error:** "No module named 'pyautogui'"

**Solution:**
```bash
pip install pyautogui pywin32 pillow
```

### Permission Denied
**Error:** "Permission denied" when executing automation

**Solution:**
- Run the app as Administrator
- Check Windows UAC settings
- Ensure target applications are not running as Administrator

### Code Editor Not Responding
**Issue:** Code editor feels laggy

**Solution:**
- Keep code files under 1000 lines
- Save frequently
- Consider breaking large flows into smaller ones

## Development

### Building from Source

1. Ensure you have Flutter installed
2. Clone the repository
3. Run:
   ```bash
   flutter pub get
   flutter pub run build_runner build
   flutter run -d windows
   ```

### Creating a Release Build

```bash
flutter build windows --release
```

The executable will be in `build\windows\runner\Release\`

### Running Tests

```bash
flutter test
```

## Technology Stack

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **Hive**: Local database
- **Python**: Automation script runtime
- **PyAutoGUI**: Mouse and keyboard control
- **PyWin32**: Windows API integration

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write tests if applicable
5. Submit a pull request

## License

This project is developed by the WILD group.

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Contact the WILD group

## Roadmap

- [ ] Visual coordinate picker (click to select screen areas)
- [ ] Flow templates and examples
- [ ] Scheduled execution
- [ ] Flow debugging and breakpoints
- [ ] Image recognition and template matching
- [ ] Multi-monitor support
- [ ] Flow export/import
- [ ] Plugin system for custom actions
- [ ] Macro recording

---

**Wild Automation** - Automate anything, anywhere.
