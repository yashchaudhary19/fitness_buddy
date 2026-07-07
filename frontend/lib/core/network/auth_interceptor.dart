import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final VoidCallback onAuthFailure;
  final Dio _refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  AuthInterceptor({required this.onAuthFailure});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    int? virtualStatusCode = response?.statusCode;

    // Handle cPanel/LiteSpeed 502 proxy wrappers for upstream errors
    if (response?.statusCode == 502 && response?.data != null) {
      final dataStr = response?.data.toString() ?? '';
      if (dataStr.contains('401') || dataStr.contains('Unauthorized')) {
        virtualStatusCode = 401;
      } else if (dataStr.contains('404') || dataStr.contains('Not Found')) {
        virtualStatusCode = 404;
      }
    }

    // Treat missing user as an auth failure and force logout
    if (virtualStatusCode == 404) {
      final data = response?.data;
      bool isUserNotFound = false;
      if (data is Map<String, dynamic>) {
        final detail = data['detail']?.toString();
        if (detail == "User associated with token not found.") {
          isUserNotFound = true;
        }
      } else if (data != null && data.toString().contains("User associated with token not found")) {
        isUserNotFound = true;
      }

      if (isUserNotFound) {
        await TokenStorage.clear();
        onAuthFailure();
        return handler.reject(err);
      }
    }

    // If unauthorized, attempt token refresh
    if (virtualStatusCode == 401) {
      final refreshToken = TokenStorage.refreshToken;
      
      // If no refresh token exists, propagate error and logout
      if (refreshToken == null) {
        onAuthFailure();
        return super.onError(err, handler);
      }

      try {
        if (kDebugMode) {
          print("Access token expired. Attempting token refresh...");
        }

        // Perform token refresh call
        final response = await _refreshDio.post(
          ApiConstants.refresh,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200 && response.data != null) {
          final resData = response.data['data'];
          if (resData == null || resData['access_token'] == null) {
            throw Exception("Invalid refresh response");
          }
          
          final newAccessToken = resData['access_token'].toString();
          final newRefreshToken = (resData['refresh_token'] ?? refreshToken).toString();

          // Save new tokens
          await TokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          if (kDebugMode) {
            print("Token refresh successful! Retrying original request.");
          }

          // Clone options and update authorization header
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          // Retry the request using a new custom Dio instance to avoid infinite loop checks
          final retryDio = Dio(BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Bypass-Tunnel-Reminder': 'true',
            },
          ));
          try {
            final retryResponse = await retryDio.request(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
              ),
            );
            return handler.resolve(retryResponse);
          } on DioException catch (retryErr) {
            return handler.reject(retryErr);
          }
        }
      } catch (refreshErr) {
        if (kDebugMode) {
          print("Token refresh failed: $refreshErr. Logging user out.");
        }
        await TokenStorage.clear();
        onAuthFailure();
        return handler.reject(err);
      }
    }

    return super.onError(err, handler);
  }
}
