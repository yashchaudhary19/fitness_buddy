import 'package:hive_flutter/hive_flutter.dart';

class TokenStorage {
  static const String boxName = 'auth_box';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyNeedsOnboarding = 'needs_onboarding';

  static Box get _box => Hive.box(boxName);

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static String? get accessToken => _box.get(keyAccessToken) as String?;
  static String? get refreshToken => _box.get(keyRefreshToken) as String?;
  static bool get needsOnboarding => _box.get(keyNeedsOnboarding, defaultValue: true) as bool;

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _box.put(keyAccessToken, accessToken);
    await _box.put(keyRefreshToken, refreshToken);
  }

  static Future<void> setNeedsOnboarding(bool value) async {
    await _box.put(keyNeedsOnboarding, value);
  }

  static Future<void> clear() async {
    await _box.delete(keyAccessToken);
    await _box.delete(keyRefreshToken);
    await _box.delete(keyNeedsOnboarding);
  }
}
