import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:provider/provider.dart';
import '../models/screen_object.dart';
import '../providers/object_provider.dart';

/// Enhanced code editor with dropdown autocomplete
class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  final ValueChanged<String>? onCodeChanged;

  const CodeEditorWidget({
    super.key,
    this.initialCode = '',
    this.onCodeChanged,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  bool _showApiReference = false;
  List<ApiItem> _apiItems = [];

  // Autocomplete state
  OverlayEntry? _autocompleteOverlay;
  List<ApiItem> _suggestions = [];
  int _selectedIndex = 0;
  String _currentWord = '';
  int _wordStartPos = 0;

  @override
  void initState() {
    super.initState();

    _controller = CodeController(
      text: widget.initialCode,
      language: python,
    );

    _controller.addListener(_onTextChanged);

    // Load initial API items (will be updated when objects are available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApiItems([]);
    });
  }

  void _onTextChanged() {
    widget.onCodeChanged?.call(_controller.text);

    // Update autocomplete
    _updateAutocomplete();
  }

  void _updateAutocomplete() {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;

    if (cursor < 0 || cursor > text.length) {
      _hideAutocomplete();
      return;
    }

    final beforeCursor = text.substring(0, cursor);
    final match = RegExp(r'[\w.]+$').firstMatch(beforeCursor);

    if (match != null && match.group(0)!.length >= 2) {
      _currentWord = match.group(0)!;
      _wordStartPos = match.start;

      print('[Autocomplete] Searching for: "$_currentWord" in ${_apiItems.length} items');

      _suggestions = _apiItems.where((item) {
        return item.name.toLowerCase().contains(_currentWord.toLowerCase());
      }).toList();

      print('[Autocomplete] Found ${_suggestions.length} suggestions');

      if (_suggestions.isNotEmpty) {
        _suggestions.sort((a, b) {
          final aStarts = a.name.toLowerCase().startsWith(_currentWord.toLowerCase());
          final bStarts = b.name.toLowerCase().startsWith(_currentWord.toLowerCase());
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          return a.name.compareTo(b.name);
        });

        _selectedIndex = 0;
        _showAutocomplete();
      } else {
        _hideAutocomplete();
      }
    } else {
      _hideAutocomplete();
    }
  }

  void _showAutocomplete() {
    _hideAutocomplete();

    print('[Autocomplete] Showing overlay with ${_suggestions.length} suggestions');

    _autocompleteOverlay = OverlayEntry(
      builder: (context) => _buildAutocompleteWidget(),
    );

    Overlay.of(context).insert(_autocompleteOverlay!);
    print('[Autocomplete] Overlay inserted');
  }

  void _rebuildAutocomplete() {
    _autocompleteOverlay?.markNeedsBuild();
  }

  Widget _buildAutocompleteWidget() {
    // Calculate approximate cursor position
    final lineHeight = 21.0; // 14px font * 1.5 line height
    final text = _controller.text.substring(0, _controller.selection.baseOffset);
    final lines = text.split('\n').length;
    final yOffset = lines * lineHeight;

    return Positioned(
      width: 450,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, yOffset),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF2D2D30),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF56585C)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(bottom: BorderSide(color: Color(0xFF56585C))),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_suggestions.length} suggestion${_suggestions.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '↑↓ Navigate  ↵ Accept  Esc Close',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Suggestions list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    itemBuilder: (ctx, index) {
                      final item = _suggestions[index];
                      final isSelected = index == _selectedIndex;

                      return InkWell(
                        onTap: () => _insertSuggestion(item),
                        onHover: (hovering) {
                          if (hovering && _selectedIndex != index) {
                            _selectedIndex = index;
                            _rebuildAutocomplete();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          color: isSelected
                              ? const Color(0xFF3E3E42)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              // Icon
                              Icon(
                                _getIcon(item.category),
                                size: 18,
                                color: _getColor(item.category),
                              ),
                              const SizedBox(width: 10),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name with highlight
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: _buildHighlightedText(item.name, _currentWord),
                                      ),
                                    ),
                                    // Signature
                                    const SizedBox(height: 2),
                                    Text(
                                      item.signature,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getColor(item.category).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getColor(item.category).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    color: _getColor(item.category),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideAutocomplete() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int lastIndex = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, lastIndex);
      if (index == -1) {
        if (lastIndex < text.length) {
          spans.add(TextSpan(text: text.substring(lastIndex)));
        }
        break;
      }

      if (index > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          color: Colors.lightBlueAccent,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ));

      lastIndex = index + query.length;
    }

    return spans;
  }

  void _insertSuggestion(ApiItem item) {
    final text = _controller.text;
    String insertText = item.name;

    // Add () after function names (check if signature contains parentheses)
    if (item.signature.contains('(')) {
      insertText = '$insertText()';
    }

    final newText = text.substring(0, _wordStartPos) +
                    insertText +
                    text.substring(_controller.selection.baseOffset);

    _controller.text = newText;

    // Position cursor inside brackets if we added them
    final cursorOffset = insertText.endsWith('()')
        ? _wordStartPos + insertText.length - 1  // Inside the brackets
        : _wordStartPos + insertText.length;     // After the text

    _controller.selection = TextSelection.collapsed(offset: cursorOffset);

    _hideAutocomplete();
    _focusNode.requestFocus();
  }

  void _loadApiItems(List<ScreenObject> objects) {
    _apiItems = [
      // Window
      ApiItem('Window.maximize', 'Window.maximize(title: str) -> bool', 'Maximize a window', 'Window'),
      ApiItem('Window.minimize', 'Window.minimize(title: str) -> bool', 'Minimize a window', 'Window'),
      ApiItem('Window.activate', 'Window.activate(title: str) -> bool', 'Focus a window', 'Window'),
      ApiItem('Window.focus', 'Window.focus(title: str) -> bool', 'Focus and wait for window to be interactable', 'Window'),
      ApiItem('Window.close', 'Window.close(title: str) -> bool', 'Close a window', 'Window'),
      ApiItem('Window.exists', 'Window.exists(title: str) -> bool', 'Check if window exists', 'Window'),

      // Mouse
      ApiItem('Mouse.click', 'Mouse.click(x: int, y: int, button="left") OR Mouse.click(object)', 'Click at coordinates or object', 'Mouse'),
      ApiItem('Mouse.move', 'Mouse.move(x: int, y: int, duration=0.0) OR Mouse.move(object)', 'Move mouse to coordinates or object', 'Mouse'),
      ApiItem('Mouse.drag', 'Mouse.drag(x: int, y: int, duration=0.5) OR Mouse.drag(object)', 'Drag mouse to coordinates or object', 'Mouse'),
      ApiItem('Mouse.scroll', 'Mouse.scroll(clicks: int)', 'Scroll mouse wheel', 'Mouse'),

      // Keyboard
      ApiItem('Keyboard.write', 'Keyboard.write(text: str, interval=0.0)', 'Type text', 'Keyboard'),
      ApiItem('Keyboard.press', 'Keyboard.press(key: str)', 'Press a key', 'Keyboard'),
      ApiItem('Keyboard.hotkey', 'Keyboard.hotkey(*keys)', 'Press key combo', 'Keyboard'),

      // Screen
      ApiItem('Screen.ocr_object', 'Screen.ocr_object(obj, language="en") -> str', 'OCR from object', 'Screen'),
      ApiItem('Screen.ocr_region', 'Screen.ocr_region(x, y, w, h, language="en") -> str', 'OCR from region', 'Screen'),
      ApiItem('Screen.screenshot', 'Screen.screenshot(region=None) -> str', 'Take screenshot', 'Screen'),

      // Utils
      ApiItem('wait', 'wait(seconds: float)', 'Pause execution', 'Utility'),
      ApiItem('log', 'log(message: str)', 'Log to console', 'Utility'),

      // Python
      ApiItem('print', 'print(*values)', 'Print to console', 'Python'),
      ApiItem('range', 'range(start, stop, step=1)', 'Generate sequence', 'Python'),
      ApiItem('len', 'len(obj) -> int', 'Get length', 'Python'),
      ApiItem('str', 'str(obj) -> str', 'Convert to string', 'Python'),
      ApiItem('int', 'int(value) -> int', 'Convert to integer', 'Python'),
      ApiItem('for', 'for i in range():', 'For loop', 'Python'),
      ApiItem('if', 'if condition:', 'If statement', 'Python'),
      ApiItem('while', 'while condition:', 'While loop', 'Python'),
      ApiItem('try', 'try:', 'Try-except block', 'Python'),

      // ScreenObjects
      ApiItem('ScreenObjects', 'ScreenObjects.{name}', 'Access screen objects', 'Objects'),
      ...objects.map((o) => ApiItem(
        'ScreenObjects.${o.name}',
        o.isPoint ? 'Point (${o.x}, ${o.y})' : 'Rect (${o.x},${o.y}) to (${o.x2},${o.y2})',
        o.description ?? (o.isPoint ? 'Point object' : 'Rectangle object'),
        'Objects',
      )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ObjectProvider>(
      builder: (context, objectProvider, child) {
        _loadApiItems(objectProvider.objects);

        return Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _focusNode.requestFocus();
                },
                child: Focus(
                  focusNode: _focusNode,
                  onKeyEvent: (node, event) {
                    _handleKeyEvent(event);
                    // Let the CodeField handle typing
                    return KeyEventResult.ignored;
                  },
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: Container(
                        color: const Color(0xFF272822), // Monokai background color
                        width: double.infinity,
                        height: double.infinity,
                        child: SingleChildScrollView(
                          child: CodeField(
                            controller: _controller,
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showApiReference) _buildApiPanel(),
          ],
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Handle autocomplete navigation
    if (_autocompleteOverlay != null && _suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
        _rebuildAutocomplete();
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _selectedIndex = (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
        _rebuildAutocomplete();
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _insertSuggestion(_suggestions[_selectedIndex]);
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _insertSuggestion(_suggestions[_selectedIndex]);
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideAutocomplete();
        return;
      }
    }

    // Ctrl+Space to manually show
    if (event.logicalKey == LogicalKeyboardKey.space &&
        HardwareKeyboard.instance.isControlPressed) {
      _updateAutocomplete();
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D30),
        border: Border(bottom: BorderSide(color: Color(0xFF56585C))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_showApiReference ? Icons.visibility_off : Icons.menu_book, size: 18),
            onPressed: () => setState(() => _showApiReference = !_showApiReference),
            tooltip: 'API Reference',
            color: Colors.white70,
          ),
          const Spacer(),
          Text(
            'Type to autocomplete • Ctrl+Space',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }


  Widget _buildApiPanel() {
    final categories = <String, List<ApiItem>>{};
    for (final item in _apiItems) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D30),
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: DefaultTabController(
        length: categories.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              indicatorColor: Colors.blue,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[500],
              tabs: categories.keys.map((cat) => Tab(text: cat)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: categories.entries.map((entry) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: entry.value.length,
                    itemBuilder: (ctx, i) {
                      final item = entry.value[i];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: Icon(_getIcon(item.category), size: 16, color: _getColor(item.category)),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                          ),
                          subtitle: Text(
                            item.signature,
                            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            color: Colors.blue,
                            onPressed: () {
                              final cursor = _controller.selection.baseOffset;
                              final text = _controller.text;
                              final newText = text.substring(0, cursor) + item.name + text.substring(cursor);
                              _controller.text = newText;
                              _controller.selection = TextSelection.collapsed(offset: cursor + item.name.length);
                              _focusNode.requestFocus();
                            },
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Window': return Icons.window;
      case 'Mouse': return Icons.mouse;
      case 'Keyboard': return Icons.keyboard;
      case 'Screen': return Icons.screenshot;
      case 'Objects': return Icons.crop_free;
      case 'Utility': return Icons.build;
      case 'Python': return Icons.code;
      default: return Icons.functions;
    }
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Window': return Colors.blue;
      case 'Mouse': return Colors.purple;
      case 'Keyboard': return Colors.orange;
      case 'Screen': return Colors.green;
      case 'Objects': return Colors.teal;
      case 'Utility': return Colors.amber;
      case 'Python': return Colors.grey;
      default: return Colors.white70;
    }
  }

  @override
  void dispose() {
    _hideAutocomplete();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class ApiItem {
  final String name;
  final String signature;
  final String description;
  final String category;

  ApiItem(this.name, this.signature, this.description, this.category);
}

