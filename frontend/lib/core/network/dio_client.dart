import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/auth_interceptor.dart';
import 'package:frontend/core/router/router.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60), // Increased timeout for slow connections
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
    ),
  );

  // Add the authentication interceptor
  dio.interceptors.add(
    AuthInterceptor(
      onAuthFailure: () {
        // Automatically switch authState to update router paths
        ref.read(authStateProvider.notifier).state = AuthState.unauthenticated;
      },
    ),
  );

  // Include verbose network logging in debug mode
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  return dio;
});
