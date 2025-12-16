import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  // Set default theme mode to light mode
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Called when user toggles Dark Mode manually
  void setDarkMode(bool enabled) {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Called on Settings page load to detect system mode
  void syncWithSystem(Brightness brightness) {
    // Keep the default theme as light even when syncing with system
    if (_themeMode == ThemeMode.system) {
      _themeMode = (brightness == Brightness.dark)
          ? ThemeMode.dark
          : ThemeMode.light;
      notifyListeners();
    }
  }
}
