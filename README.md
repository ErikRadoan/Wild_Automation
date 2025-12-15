<div align="center">
  <img src="assets/wild_automate_logo.png" alt="WILD Automate Logo" width="200"/>
  
  # WILD Automate
  
  **UI Automation Made Simple**
  
  *Powerful desktop automation for Windows*
  
  [![License](https://img.shields.io/badge/license-Proprietary-blue.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/windows)
  [![Python](https://img.shields.io/badge/python-3.7+-green.svg)](https://www.python.org/)
  [![Release](https://img.shields.io/github/v/release/ErikRadoan/Wild_Automation)](https://github.com/ErikRadoan/Wild_Automation/releases)
  
</div>

---

## 📖 Overview

**WILD Automate** is a professional desktop automation tool that empowers you to automate repetitive tasks on Windows. Whether you're automating data entry, testing applications, or creating complex workflows, WILD Automate provides an intuitive interface and powerful Python-based scripting engine to get the job done.

### Key Features

- ✨ **User-Friendly Interface** - Intuitive point-and-click coordinate selection
- 🐍 **Python-Powered** - Full Python scripting support with custom automation API
- 🎯 **Visual Object Management** - Define and manage screen coordinates and regions
- 🔍 **OCR Integration** - Extract text from screen regions using EasyOCR
- 🖱️ **Mouse & Keyboard Control** - Automate clicks, typing, and hotkeys
- 🪟 **Window Management** - Focus, maximize, minimize, and control application windows
- 🌍 **Multi-Language Support** - English and German interface
- 🎨 **Modern UI** - Clean interface with light and dark themes

---

## 💾 Installation

### Quick Install

1. **Download** the latest release from the [Releases page](https://github.com/ErikRadoan/Wild_Automation/releases)
2. **Extract** the ZIP file to your desired location
3. **Run** `wild_automation.exe`
4. **Install Python dependencies** via Settings → Dependencies

### Requirements

- **OS:** Windows 10/11 (64-bit)
- **Python:** 3.7 or higher (must be added to PATH)
- **RAM:** 4GB minimum, 8GB recommended
- **Storage:** 2GB for application and dependencies

📚 **Detailed installation guide:** [Installation Wiki](https://github.com/ErikRadoan/Wild_Automation/wiki/Installation)

---

## 🚀 Quick Start

### Create Your First Automation

1. **Create a Project** - Launch WILD Automate and create a new project
2. **Define Objects** - Use the Objects tab to capture screen coordinates
3. **Write a Flow** - Create automation scripts using Python and the WILD API
4. **Execute** - Run your automation and monitor the output

```python
# Example: Simple automation flow
from wild_api import Mouse, Keyboard, Window, Utils

Window.focus("Notepad")
Utils.wait(0.5)
Keyboard.write("Hello from WILD Automate!")
Utils.log("Automation complete!")
```

📚 **Full tutorial:** [Getting Started Guide](https://github.com/ErikRadoan/Wild_Automation/wiki/Getting-Started)

---

## 📚 Documentation

Comprehensive documentation is available in the [Wiki](https://github.com/ErikRadoan/Wild_Automation/wiki):

### User Guides
- **[Getting Started](https://github.com/ErikRadoan/Wild_Automation/wiki/Getting-Started)** - Your first automation
- **[Screen Objects](https://github.com/ErikRadoan/Wild_Automation/wiki/Screen-Objects)** - Managing coordinates and regions
- **[Automation Flows](https://github.com/ErikRadoan/Wild_Automation/wiki/Automation-Flows)** - Writing Python automation scripts
- **[Execution](https://github.com/ErikRadoan/Wild_Automation/wiki/Execution)** - Running and monitoring flows

### API Reference
- **[Mouse Control](https://github.com/ErikRadoan/Wild_Automation/wiki/API-Mouse)** - Click, move, drag, scroll
- **[Keyboard Control](https://github.com/ErikRadoan/Wild_Automation/wiki/API-Keyboard)** - Type text and send hotkeys
- **[Window Management](https://github.com/ErikRadoan/Wild_Automation/wiki/API-Window)** - Focus and control windows
- **[Screen Operations](https://github.com/ErikRadoan/Wild_Automation/wiki/API-Screen)** - OCR and screenshots
- **[Utilities](https://github.com/ErikRadoan/Wild_Automation/wiki/API-Utils)** - Helper functions

### Additional Resources
- **[Troubleshooting](https://github.com/ErikRadoan/Wild_Automation/wiki/Troubleshooting)** - Common issues and solutions
- **[FAQ](https://github.com/ErikRadoan/Wild_Automation/wiki/FAQ)** - Frequently asked questions
- **[Examples](https://github.com/ErikRadoan/Wild_Automation/wiki/Examples)** - Sample automation flows

---

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](https://github.com/ErikRadoan/Wild_Automation/wiki/Contributing) before submitting pull requests.

### Reporting Issues

Found a bug? [Open an issue](https://github.com/ErikRadoan/Wild_Automation/issues) with:
- Steps to reproduce
- Expected vs actual behavior
- Screenshots and error messages
- System information

---

## 📋 System Requirements

### Minimum
- Windows 10 (64-bit), 4GB RAM, Python 3.7+

### Recommended  
- Windows 11 (64-bit), 8GB RAM, Python 3.10+

---

## 📄 License

This repository does not represent the views, work, or intellectual property
of the author's current or past employers.

The employer has **no involvement** in the design, development, testing,
deployment, or maintenance of this project.

See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev/) - UI Framework
- [Python](https://www.python.org/) - Automation Runtime
- [PyAutoGUI](https://pyautogui.readthedocs.io/) - Mouse & Keyboard Control
- [EasyOCR](https://github.com/JaidedAI/EasyOCR) - Text Recognition
- [PyWin32](https://github.com/mhammond/pywin32) - Windows Integration

---

<div align="center">
  
  **WILD Automate** - *Automate Anything, Anywhere*
  
  Made with ❤️ by the WILD Group
  
  [Download](https://github.com/ErikRadoan/Wild_Automation/releases) • [Wiki](https://github.com/ErikRadoan/Wild_Automation/wiki) • [Report Bug](https://github.com/ErikRadoan/Wild_Automation/issues) • [Request Feature](https://github.com/ErikRadoan/Wild_Automation/issues)
  
</div>

