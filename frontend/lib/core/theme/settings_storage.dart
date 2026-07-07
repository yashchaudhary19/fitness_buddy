import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsStorage {
  static const String boxName = 'settings_box';
  static const String keyThemeMode = 'theme_mode';

  static Box get _box => Hive.box(boxName);

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static ThemeMode get themeMode {
    final modeString = _box.get(keyThemeMode, defaultValue: 'dark') as String;
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
      case ThemeMode.dark:
      default:
        modeString = 'dark';
        break;
    }
    await _box.put(keyThemeMode, modeString);
  }
}
