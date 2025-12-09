import 'package:flutter/material.dart';

/// Localization service for multi-language support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_title': 'WILD Automate',
      'app_subtitle': 'UI Automation Made Simple',
      'version': 'Version',
      'close': 'Close',
      'cancel': 'Cancel',
      'save': 'Save',
      'saved': 'Saved',
      'flow_saved': 'Flow saved',
      'delete': 'Delete',
      'create': 'Create',
      'edit': 'Edit',
      'back': 'Back',
      'continue': 'Continue',
      'done': 'Done',

      // Project Selection
      'new_project': 'New Project',
      'open_project': 'Open Project',
      'python_setup': 'Python Setup',
      'settings': 'Settings',
      'about': 'About',
      'recent_projects': 'Recent Projects',
      'no_recent_projects': 'No recent projects',
      'create_or_open_project': 'Create or open a project to get started',

      // Settings
      'theme': 'Theme',
      'language': 'Language',
      'dark_theme': 'Dark',
      'light_theme': 'Light',
      'english': 'English',
      'german': 'Deutsch (German)',

      // Navigation
      'objects': 'Objects',
      'flow': 'Flow',
      'execute': 'Execute',
      'return_to_projects': 'Return to Project Selection',

      // Execute Screen
      'flow_configuration': 'Flow Configuration',
      'select_flow': 'Select Flow',
      'input_variables': 'Input Variables',
      'output_variables': 'Output Variables',
      'add': 'Add',
      'no_input_variables': 'No input variables selected',
      'no_output_variables': 'No output variables selected',
      'execute_flow': 'Execute Flow',
      'cancel_execution': 'Cancel Execution',
      'installing': 'Installing...',
      'install_missing': 'Install Missing',

      // About
      'developed_by': 'Developed by the WILD group.',
      'copyright': '© {year} WILD group. All rights reserved.',
    },
    'de': {
      // General
      'app_title': 'WILD Automate',
      'app_subtitle': 'UI-Automatisierung leicht gemacht',
      'version': 'Version',
      'close': 'Schließen',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'saved': 'Gespeichert',
      'flow_saved': 'Ablauf gespeichert',
      'delete': 'Löschen',
      'create': 'Erstellen',
      'edit': 'Bearbeiten',
      'back': 'Zurück',
      'continue': 'Weiter',
      'done': 'Fertig',

      // Project Selection
      'new_project': 'Neues Projekt',
      'open_project': 'Projekt öffnen',
      'python_setup': 'Python-Setup',
      'settings': 'Einstellungen',
      'about': 'Über',
      'recent_projects': 'Letzte Projekte',
      'no_recent_projects': 'Keine letzten Projekte',
      'create_or_open_project': 'Erstellen oder öffnen Sie ein Projekt, um zu beginnen',

      // Settings
      'theme': 'Design',
      'language': 'Sprache',
      'dark_theme': 'Dunkel',
      'light_theme': 'Hell',
      'english': 'English (Englisch)',
      'german': 'Deutsch',

      // Navigation
      'objects': 'Objekte',
      'flow': 'Ablauf',
      'execute': 'Ausführen',
      'return_to_projects': 'Zurück zur Projektauswahl',

      // Execute Screen
      'flow_configuration': 'Ablauf-Konfiguration',
      'select_flow': 'Ablauf auswählen',
      'input_variables': 'Eingabevariablen',
      'output_variables': 'Ausgabevariablen',
      'add': 'Hinzufügen',
      'no_input_variables': 'Keine Eingabevariablen ausgewählt',
      'no_output_variables': 'Keine Ausgabevariablen ausgewählt',
      'execute_flow': 'Ablauf ausführen',
      'cancel_execution': 'Ausführung abbrechen',
      'installing': 'Installiere...',
      'install_missing': 'Fehlende installieren',

      // About
      'developed_by': 'Entwickelt von der WILD-Gruppe.',
      'copyright': '© {year} WILD-Gruppe. Alle Rechte vorbehalten.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters
  String get appTitle => translate('app_title');
  String get appSubtitle => translate('app_subtitle');
  String get version => translate('version');
  String get close => translate('close');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get saved => translate('saved');
  String get flowSaved => translate('flow_saved');
  String get delete => translate('delete');
  String get create => translate('create');
  String get edit => translate('edit');
  String get back => translate('back');
  String get continueText => translate('continue');
  String get done => translate('done');

  String get newProject => translate('new_project');
  String get openProject => translate('open_project');
  String get pythonSetup => translate('python_setup');
  String get settings => translate('settings');
  String get about => translate('about');
  String get recentProjects => translate('recent_projects');
  String get noRecentProjects => translate('no_recent_projects');
  String get createOrOpenProject => translate('create_or_open_project');

  String get theme => translate('theme');
  String get language => translate('language');
  String get darkTheme => translate('dark_theme');
  String get lightTheme => translate('light_theme');
  String get english => translate('english');
  String get german => translate('german');

  String get objects => translate('objects');
  String get flow => translate('flow');
  String get execute => translate('execute');
  String get returnToProjects => translate('return_to_projects');

  String get flowConfiguration => translate('flow_configuration');
  String get selectFlow => translate('select_flow');
  String get inputVariables => translate('input_variables');
  String get outputVariables => translate('output_variables');
  String get add => translate('add');
  String get noInputVariables => translate('no_input_variables');
  String get noOutputVariables => translate('no_output_variables');
  String get executeFlow => translate('execute_flow');
  String get cancelExecution => translate('cancel_execution');
  String get installing => translate('installing');
  String get installMissing => translate('install_missing');

  String get developedBy => translate('developed_by');
  String copyright(int year) => translate('copyright').replaceAll('{year}', year.toString());
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

