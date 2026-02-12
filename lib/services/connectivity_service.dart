import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service to monitor network connectivity status
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  List<ConnectivityResult> _connectionStatus = [];
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  void _init() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectionStatus = results;
    _isConnected = !results.contains(ConnectivityResult.none);
    notifyListeners();
  }

  /// Check current connectivity
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
