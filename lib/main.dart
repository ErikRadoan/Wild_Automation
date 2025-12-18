import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'models/project.dart';
import 'services/storage_service.dart';
import 'services/settings_service.dart';
import 'services/update_service.dart';
import 'services/localization_service.dart';
import 'services/code_analyzer_service.dart';
import 'services/python_execution_service.dart';
import 'providers/object_provider.dart';
import 'providers/flow_provider.dart';
import 'providers/execution_provider.dart';
import 'providers/overlay_provider.dart';
import 'screens/objects_screen.dart';
import 'screens/flow_screen.dart';
import 'screens/execute_screen.dart';
import 'screens/project_selection_screen.dart';
import 'screens/overlay_screen.dart';
import 'screens/loading_screen.dart';

void main(List<String> args) async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();


  const windowOptions = WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1000, 700),
    center: true,
    title: 'WILD Automate',
    titleBarStyle: TitleBarStyle.normal,
    backgroundColor: Colors.transparent, // Enable transparent background support
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();

    // Set window icon
    try {
      await windowManager.setIcon('assets/wild_automate_logo.png');
    } catch (e) {
      debugPrint('Error setting window icon: $e');
    }
  });

  // Run app with loading screen first
  runApp(const WildAutomationAppLoader());
}

/// App loader that shows loading screen during initialization
class WildAutomationAppLoader extends StatefulWidget {
  const WildAutomationAppLoader({super.key});

  @override
  State<WildAutomationAppLoader> createState() => _WildAutomationAppLoaderState();
}

class _WildAutomationAppLoaderState extends State<WildAutomationAppLoader> with SingleTickerProviderStateMixin {
  StorageService? _storage;
  SettingsService? _settings;
  UpdateService? _updateService;
  bool _isLoading = true;
  String _loadingMessage = 'Initializing...';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.value = 1.0; // Start fully visible
    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize storage
      setState(() => _loadingMessage = 'Loading storage...');
      final storage = StorageService();
      await storage.initialize();
      await Future.delayed(const Duration(milliseconds: 300)); // Smooth transition

      // Initialize settings
      setState(() => _loadingMessage = 'Loading settings...');
      final settings = SettingsService();
      await settings.initialize();
      await Future.delayed(const Duration(milliseconds: 300)); // Smooth transition

      // Initialize update service
      setState(() => _loadingMessage = 'Checking for updates...');
      final updateService = UpdateService();
      await updateService.checkForUpdates();
      await Future.delayed(const Duration(milliseconds: 300)); // Smooth transition

      // Mark as loaded
      setState(() {
        _storage = storage;
        _settings = settings;
        _updateService = updateService;
        _loadingMessage = 'Ready!';
      });

      // Small delay to show "Ready!" message
      await Future.delayed(const Duration(milliseconds: 500));

      // Fade out loading screen
      await _fadeController.reverse();

      setState(() => _isLoading = false);

      // Fade in main app
      _fadeController.forward();
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() => _loadingMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: (_isLoading || _storage == null || _settings == null || _updateService == null)
          ? MaterialApp(
              key: const ValueKey('loading'),
              debugShowCheckedModeBanner: false,
              home: LoadingScreen(message: _loadingMessage),
            )
          : WildAutomationApp(
              key: const ValueKey('main'),
              storage: _storage!,
              settings: _settings!,
              updateService: _updateService!,
            ),
    );
  }
}

class WildAutomationApp extends StatelessWidget {
  final StorageService storage;
  final SettingsService settings;
  final UpdateService updateService;

  const WildAutomationApp({
    super.key,
    required this.storage,
    required this.settings,
    required this.updateService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<UpdateService>.value(value: updateService),
        Provider<CodeAnalyzerService>(
          create: (_) => CodeAnalyzerService(),
        ),
        Provider<PythonExecutionService>(
          create: (_) => PythonExecutionService(),
        ),
        ChangeNotifierProvider<ObjectProvider>(
          create: (context) => ObjectProvider(context.read<StorageService>()),
        ),
        ChangeNotifierProvider<FlowProvider>(
          create: (context) => FlowProvider(
            context.read<StorageService>(),
            context.read<CodeAnalyzerService>(),
          ),
        ),
        ChangeNotifierProvider<ExecutionProvider>(
          create: (context) => ExecutionProvider(
            context.read<PythonExecutionService>(),
          ),
        ),
        ChangeNotifierProvider<OverlayProvider>(
          create: (_) => OverlayProvider(),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settingsService, child) {
          return MaterialApp(
            title: 'WILD Automate',
            debugShowCheckedModeBanner: false,

            // Localization
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('de', ''),
            ],
            locale: Locale(settingsService.languageCode, ''),

            // Theme
            themeMode: settingsService.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),

            home: ProjectSelectionScreen(storage: storage),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF56585C),
        primary: const Color(0xFF56585C),
        secondary: const Color(0xFFB5B7BB),
        surface: const Color(0xFFF5F5F5),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        color: Color(0xFFFFFFFF),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFB5B7BB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF56585C), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: const Color(0xFF56585C),
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: Color(0xFF56585C),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF56585C),
        primary: const Color(0xFFB5B7BB),
        secondary: const Color(0xFF56585C),
        surface: const Color(0xFF2D2D30),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D30),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        color: Color(0xFF2D2D30),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: Color(0xFF2D2D30),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF56585C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFB5B7BB), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF252526),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: const Color(0xFF56585C),
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: Color(0xFF56585C),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFB5B7BB)),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
      ),
      dividerColor: const Color(0xFF56585C),
      iconTheme: const IconThemeData(color: Color(0xFFB5B7BB)),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Project project;
  final StorageService storage;

  const MainScreen({
    super.key,
    required this.project,
    required this.storage,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ObjectsScreen(),
    FlowScreen(),
    ExecuteScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set window to opaque initially
    _setWindowOpacity(1.0);
  }

  Future<void> _setWindowOpacity(double opacity) async {
    try {
      await windowManager.setOpacity(opacity);
    } catch (e) {
      debugPrint('Error setting window opacity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OverlayProvider>(
      builder: (context, overlayProvider, child) {
        // When entering overlay mode
        if (overlayProvider.isInOverlayMode) {
          _enterOverlayMode();
          return Material(
            color: Colors.transparent, // Fully transparent material
            child: OverlayScreen(
              mode: overlayProvider.mode!,
              objects: overlayProvider.objects,
              firstPointX: overlayProvider.firstPointX,
              firstPointY: overlayProvider.firstPointY,
              onCoordinateSelected: (x, y) {
                overlayProvider.handleCoordinateSelected(x, y);
                _exitOverlayMode();
              },
              onClose: () {
                overlayProvider.exitOverlayMode();
                _exitOverlayMode();
              },
            ),
          );
        }

        // Normal mode - show app bar and navigation
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.apps),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'WILD',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB5B7BB) : const Color(0xFF56585C),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextSpan(
                    text: ' Automate',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Row(
        children: [
          Container(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF5F5F5),
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF5F5F5),
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.location_on_outlined),
                        selectedIcon: const Icon(Icons.location_on),
                        label: Text(l10n.objects),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.code_outlined),
                        selectedIcon: const Icon(Icons.code),
                        label: Text(l10n.flow),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.play_circle_outline),
                        selectedIcon: const Icon(Icons.play_circle),
                        label: Text(l10n.execute),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Tooltip(
                  message: l10n.returnToProjects,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ProjectSelectionScreen(storage: widget.storage),
                        ),
                      );
                    },
                    color: const Color(0xFF56585C),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    ); // End of Scaffold
      }, // End of Consumer builder
    ); // End of Consumer
  } // End of build method

  void _enterOverlayMode() async {
    // Make window fullscreen with transparent background
    // This makes empty areas transparent but keeps our drawings opaque
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setBackgroundColor(Colors.transparent);
  }

  void _exitOverlayMode() async {
    // Restore window state with normal background
    await windowManager.setFullScreen(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setBackgroundColor(const Color(0xFFF5F5F5)); // Restore normal background
    await _setWindowOpacity(1.0);
  }
}
