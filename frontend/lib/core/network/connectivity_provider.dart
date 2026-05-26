import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'package:frontend/core/constants/api_constants.dart';

class ConnectivityState {
  final bool isConnected;
  final bool isChecking;

  ConnectivityState({
    this.isConnected = true,
    this.isChecking = false,
  });
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _pingTimer;

  ConnectivityNotifier() : super(ConnectivityState()) {
    // Start periodic background check every 15 seconds
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) => checkConnection());
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> checkConnection() async {
    state = ConnectivityState(isConnected: state.isConnected, isChecking: true);
    
    try {
      if (kIsWeb) {
        // On web, dart:io InternetAddress is unsupported and throws UnsupportedError.
        // We ping the backend health endpoint using Dio.
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ));
        final response = await dio.get('${ApiConstants.baseUrl}/health');
        state = ConnectivityState(isConnected: response.statusCode == 200, isChecking: false);
        return;
      }

      // Parse host from API base URL (e.g. 10.0.2.2 or localhost)
      final uri = Uri.parse(ApiConstants.baseUrl);
      final result = await InternetAddress.lookup(uri.host).timeout(const Duration(seconds: 4));
      
      final bool connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      state = ConnectivityState(isConnected: connected, isChecking: false);
    } catch (_) {
      state = ConnectivityState(isConnected: false, isChecking: false);
    }
  }
}

// Connectivity Provider declaration
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});
