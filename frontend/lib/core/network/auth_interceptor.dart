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
    // Treat missing user as an auth failure and force logout
    if (err.response?.statusCode == 404) {
      final data = err.response?.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail']?.toString();
        if (detail == "User associated with token not found.") {
          await TokenStorage.clear();
          onAuthFailure();
          return handler.reject(err);
        }
      }
    }

    // If unauthorized, attempt token refresh
    if (err.response?.statusCode == 401) {
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
          final retryDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
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
