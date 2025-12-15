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
      width: 480,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, yOffset),
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF252526),
          shadowColor: Colors.black.withValues(alpha: 0.5),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 350),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF56585C),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D2D30),
                  Color(0xFF252526),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E1E), Color(0xFF252526)],
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF56585C), width: 1),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_suggestions.length} suggestion${_suggestions.length == 1 ? '' : 's'} for "$_currentWord"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E3E42),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF56585C)),
                        ),
                        child: Text(
                          '↑↓  Tab  Esc',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Suggestions list with improved styling
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (ctx, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey[800],
                      indent: 12,
                      endIndent: 12,
                    ),
                    itemBuilder: (ctx, index) {
                      final item = _suggestions[index];
                      final isSelected = index == _selectedIndex;

                      return InkWell(
                        onTap: () => _insertSuggestion(item),
                        onHover: (hovering) {
                          if (hovering && _selectedIndex != index) {
                            setState(() => _selectedIndex = index);
                            _rebuildAutocomplete();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF56585C).withValues(alpha: 0.4)
                                : Colors.transparent,
                            border: isSelected
                                ? Border(
                                    left: BorderSide(
                                      color: _getColor(item.category),
                                      width: 3,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Icon with background
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getColor(item.category).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getColor(item.category).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  _getIcon(item.category),
                                  size: 16,
                                  color: _getColor(item.category),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name with highlight
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                        children: _buildHighlightedText(item.name, _currentWord),
                                      ),
                                    ),
                                    // Signature
                                    const SizedBox(height: 3),
                                    Text(
                                      item.signature,
                                      style: TextStyle(
                                        color: isSelected ? Colors.grey[300] : Colors.grey[500],
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getColor(item.category).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getColor(item.category).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    color: _getColor(item.category),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
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
                child: FocusScope(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && _autocompleteOverlay != null && _suggestions.isNotEmpty) {
                      // Handle Tab
                      if (event.logicalKey == LogicalKeyboardKey.tab) {
                        _insertSuggestion(_suggestions[_selectedIndex]);
                        return KeyEventResult.handled;
                      }
                      // Handle Arrow Up
                      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _selectedIndex = (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
                        _rebuildAutocomplete();
                        return KeyEventResult.handled;
                      }
                      // Handle Arrow Down
                      else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
                        _rebuildAutocomplete();
                        return KeyEventResult.handled;
                      }
                      // Handle Enter
                      else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        _insertSuggestion(_suggestions[_selectedIndex]);
                        return KeyEventResult.handled;
                      }
                      // Handle Escape
                      else if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _hideAutocomplete();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Focus(
                    focusNode: _focusNode,
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: CodeTheme(
                        data: CodeThemeData(styles: monokaiSublimeTheme),
                        child: Container(
                          color: const Color(0xFF272822),
                          width: double.infinity,
                          height: double.infinity,
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: CodeField(
                              controller: _controller,
                              textStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.5,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFF272822),
                              ),
                              padding: EdgeInsets.zero,
                              lineNumberStyle: const LineNumberStyle(
                                width: 50,
                                textAlign: TextAlign.right,
                                margin: 8,
                              ),
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


  Widget _buildToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF3E3E42) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // Editor title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF56585C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.code,
                  size: 20,
                  color: Color(0xFF56585C),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Python Flow Editor',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Start typing to see suggestions',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Keyboard shortcuts hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF3E3E42) : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildKeyHint('Ctrl', 'Space', 'Show suggestions'),
                const SizedBox(width: 16),
                _buildKeyHint('Tab', null, 'Accept suggestion'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // API Reference toggle button
          Material(
            color: _showApiReference
                ? const Color(0xFF56585C)
                : (isDark ? const Color(0xFF2D2D30) : const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _showApiReference = !_showApiReference),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _showApiReference
                        ? const Color(0xFF56585C)
                        : (isDark ? const Color(0xFF3E3E42) : const Color(0xFFE0E0E0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 18,
                      color: _showApiReference
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'API Reference',
                      style: TextStyle(
                        color: _showApiReference
                            ? Colors.white
                            : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_showApiReference) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyHint(String key1, String? key2, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3E3E42) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? const Color(0xFF56585C) : const Color(0xFFD0D0D0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Text(
            key1,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
        if (key2 != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3E3E42) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? const Color(0xFF56585C) : const Color(0xFFD0D0D0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Text(
              key2,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }


  Widget _buildApiPanel() {
    final categories = <String, List<ApiItem>>{};
    for (final item in _apiItems) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: const Border(top: BorderSide(color: Color(0xFF56585C), width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: DefaultTabController(
        length: categories.length,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF252526),
                border: Border(bottom: BorderSide(color: Color(0xFF56585C))),
              ),
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF56585C),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: categories.keys.map((cat) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIcon(cat), size: 16),
                        const SizedBox(width: 6),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: categories.entries.map((entry) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: entry.value.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                    itemBuilder: (ctx, i) {
                      final item = entry.value[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getColor(item.category).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              final cursor = _controller.selection.baseOffset;
                              final text = _controller.text;
                              final newText = text.substring(0, cursor) + item.name + text.substring(cursor);
                              _controller.text = newText;
                              _controller.selection = TextSelection.collapsed(offset: cursor + item.name.length);
                              _focusNode.requestFocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _getColor(item.category).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      _getIcon(item.category),
                                      size: 16,
                                      color: _getColor(item.category),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.signature,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                            fontFamily: 'monospace',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

