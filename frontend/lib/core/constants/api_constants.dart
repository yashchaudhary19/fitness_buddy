import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    if (Platform.isAndroid) {
      // With adb reverse tcp:8000 tcp:8000, we can use localhost
      return "http://localhost:8000";
    }
    return "http://127.0.0.1:8000";
  }

  // Auth paths
  static const String register = "/api/auth/register";
  static const String login = "/api/auth/login";
  static const String refresh = "/api/auth/refresh";
  static const String logout = "/api/auth/logout";
  static const String me = "/api/auth/me";
  static const String updateProfile = "/api/auth/me";
  static const String updatePassword = "/api/auth/password";
  static const String googleAuth = "/api/auth/google";

  // Goals paths
  static const String goals = "/api/goals/";

  // Foods paths
  static const String searchFoods = "/api/foods/search";
  static const String barcodeLookup = "/api/foods/barcode";
  static const String customFood = "/api/foods/custom";

  // Diary paths
  static const String diary = "/api/diary/";
  static const String diarySummary = "/api/diary/summary";
  static const String diaryEntries = "/api/diary/entries";

  // Water paths
  static const String water = "/api/water/";

  // Exercises paths
  static const String exercises = "/api/exercises/";
  static const String exerciseLibrary = "/api/exercises/library";

  // Weight paths
  static const String weight = "/api/weight/";
  static const String weightStats = "/api/weight/stats";

  // Progress paths
  static const String measurements = "/api/progress/measurements";
  static const String streak = "/api/progress/streak";
  static const String caloriesTimeline = "/api/progress/calories-timeline";
  static const String macrosTimeline = "/api/progress/macros-timeline";
  static const String weightTimeline = "/api/progress/weight-timeline";

  // AI paths
  static const String mealScan = "/api/ai/meal-scan";
  static const String voiceParse = "/api/ai/voice-parse";
  static const String insights = "/api/ai/insights";
  static const String aiChat = "/api/ai/chat";
  static const String aiDebrief = "/api/ai/debrief";
  static const String aiWeightInterpretation = "/api/ai/weight-interpretation";
}
