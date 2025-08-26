import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityUtils {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
  
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      if (kDebugMode) {
        print('Connectivity check error: $e');
      }
      return false;
    }
  }
}