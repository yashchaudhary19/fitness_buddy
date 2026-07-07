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

  String _sanitizeErrorMessage(String rawMessage, {int? statusCode}) {
    final lower = rawMessage.toLowerCase();
    
    // Connection refused / SocketException
    if (lower.contains("socketexception") || 
        lower.contains("connection refused") || 
        lower.contains("errno = 111") ||
        lower.contains("failed host lookup")) {
      return "Unable to connect to the server. Please check your network connection and try again.";
    }
    
    // DB / SQL Dump errors
    if (lower.contains("sql") || 
        lower.contains("database") || 
        lower.contains("relation") || 
        lower.contains("postgres") || 
        lower.contains("sqlite") || 
        lower.contains("sqlalchemy") || 
        lower.contains("table") || 
        lower.contains("column")) {
      return "A database configuration error occurred. Please try again later.";
    }
    
    // Format / Parsing errors
    if (lower.contains("formatexception") || 
        lower.contains("unexpected character") || 
        lower.contains("type 'string' is not a subtype")) {
      return "Received invalid data from the server. Please try again later.";
    }
    
    // Internal Server errors (500)
    if (statusCode == 500 || lower.contains("internal server error")) {
      return "The server encountered an error processing this request. Please try again later.";
    }
    
    // Clean up any developer exception prefixes
    String clean = rawMessage;
    final prefixes = ["apiapiapiapiapiapiapiapi", "ApiException: ", "Exception: ", "TypeError: ", "FormatException: ", "Error: "];
    for (final prefix in prefixes) {
      if (clean.startsWith(prefix)) {
        clean = clean.substring(prefix.length);
      }
    }
    
    if (clean.trim().isEmpty) {
      return "An unexpected error occurred. Please try again.";
    }
    
    return clean;
  }

  ApiException _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      int statusCode = response.statusCode ?? 500;
      dynamic rawData = response.data;
      String? errorCode;
      String errorMessage = "An unexpected error occurred. Please try again.";

      // Handle 503 Service Unavailable (DB temporarily down)
      if (statusCode == 503) {
        String detail = "The service is temporarily unavailable. Please try again in a moment.";
        if (rawData is Map<String, dynamic>) {
          final d = rawData['detail']?.toString();
          if (d != null && d.isNotEmpty) detail = d;
        }
        return ApiException(detail, statusCode: 503);
      }

      // Handle cPanel/LiteSpeed 502 proxy wrappers for upstream errors
      if (statusCode == 502 && rawData != null) {
        final dataStr = rawData.toString();
        if (dataStr.contains("401") || dataStr.contains("Unauthorized")) {
          statusCode = 401;
          errorMessage = "Your session has expired. Please log in again.";
        } else if (dataStr.contains("404") || dataStr.contains("Not Found")) {
          statusCode = 404;
          errorMessage = "Requested resource not found.";
        } else if (dataStr.contains("400") || dataStr.contains("Bad Request")) {
          statusCode = 400;
          errorMessage = "Invalid request parameters.";
        } else if (dataStr.contains("422") || dataStr.contains("Unprocessable Entity")) {
          statusCode = 422;
          errorMessage = "Validation error occurred.";
        } else if (dataStr.contains("500") || dataStr.contains("Internal Server Error")) {
          statusCode = 500;
          errorMessage = "The server encountered an error. Please try again.";
        } else if (dataStr.contains("503") || dataStr.contains("Service Unavailable")) {
          statusCode = 503;
          errorMessage = "The service is temporarily unavailable. Please try again in a moment.";
        } else {
          // Generic 502 — server is restarting or temporarily unavailable
          errorMessage = "The server is temporarily unavailable. Please wait a moment and try again.";
        }
      } else {
        try {
          if (rawData is Map<String, dynamic>) {
            final errorMsg = rawData['detail'] ?? rawData['error'] ?? rawData['message'] ?? e.message;
            errorMessage = _sanitizeErrorMessage(errorMsg.toString(), statusCode: statusCode);
            errorCode = rawData['error']?.toString();
          } else {
            errorMessage = _sanitizeErrorMessage(e.message ?? errorMessage, statusCode: statusCode);
          }
        } catch (_) {}
      }

      return ApiException(
        errorMessage,
        statusCode: statusCode,
        errorCode: errorCode,
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
        final msg = e.message ?? "";
        return ApiException(_sanitizeErrorMessage(msg));
    }
  }

  Future<ResponseEnvelope> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(_sanitizeErrorMessage(e.toString()));
    }
  }

  Future<ResponseEnvelope> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(_sanitizeErrorMessage(e.toString()));
    }
  }

  Future<ResponseEnvelope> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(_sanitizeErrorMessage(e.toString()));
    }
  }

  Future<ResponseEnvelope> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return ResponseEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(_sanitizeErrorMessage(e.toString()));
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
      throw ApiException(_sanitizeErrorMessage(e.toString()));
    }
  }
}

// Riverpod Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});
