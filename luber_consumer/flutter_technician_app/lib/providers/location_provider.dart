import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../config/constants.dart';

class LocationProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Position? _currentPosition;
  bool _isTracking = false;
  Timer? _locationUpdateTimer;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  Future<void> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void startTracking(String jobId) async {
    if (_isTracking) return;
    
    _isTracking = true;
    notifyListeners();

    await getCurrentLocation();

    _locationUpdateTimer = Timer.periodic(
      Duration(seconds: AppConstants.locationUpdateIntervalSeconds),
      (timer) async {
        await getCurrentLocation();
        if (_currentPosition != null) {
          await _updateLocationOnServer(jobId);
        }
      },
    );
  }

  void stopTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _updateLocationOnServer(String jobId) async {
    if (_currentPosition == null) return;

    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) return;

      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/location/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jobId': jobId,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        }),
      );
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
