import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';

class ResponseEnvelope {
  final bool success;
  final dynamic data;
  final String? message;
  final String? error;

  ResponseEnvelope({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ResponseEnvelope.fromJson(Map<String, dynamic> json) {
    return ResponseEnvelope(
      success: json['success'] as bool? ?? false,
      data: json['data'],
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  ApiException _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      try {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final errorMsg = data['detail'] ?? data['error'] ?? data['message'] ?? e.message;
          return ApiException(
            errorMsg.toString(),
            statusCode: response.statusCode,
            errorCode: data['error'],
          );
        }
      } catch (_) {}
      return ApiException(
        "Server returned an error (code ${response.statusCode})",
        statusCode: response.statusCode,
      );
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException("Connection timed out. Please check your internet connection.");
      case DioExceptionType.connectionError:
        return ApiException("Cannot reach the server. Please check your network or verify the backend is running.");
      default:
        if (e.message != null && e.message!.contains("SocketException")) {
          return ApiException("Network connection error. Please check your internet connection.");
        }
        return ApiException("A network error occurred. Please try again.");
    }
  }

  Future<ResponseEnvelope> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ResponseEnvelope> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ResponseEnvelope> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ResponseEnvelope> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ResponseEnvelope> upload(
    String path,
    List<int> fileBytes,
    String fileName, {
    String mimeType = "image/jpeg",
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final multipartFile = MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await _dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}

// Riverpod Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});
