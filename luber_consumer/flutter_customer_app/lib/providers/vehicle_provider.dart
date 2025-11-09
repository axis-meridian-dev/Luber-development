import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_model.dart';
import '../config/constants.dart';

class VehicleProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  VehicleModel? get defaultVehicle {
    if (_vehicles.isEmpty) return null;
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.isDefault);
    } catch (_) {
      return _vehicles.first;
    }
  }

  /// Fetch all vehicles for the current user
  Future<void> fetchVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/vehicles'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final vehiclesData = data['vehicles'] as List;
        _vehicles = vehiclesData.map((v) => VehicleModel.fromJson(v)).toList();
        _error = null;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch vehicles');
      }
    } catch (e) {
      _error = e.toString();
      _vehicles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new vehicle
  Future<bool> addVehicle({
    required String make,
    required String model,
    required int year,
    required String vehicleType,
    required String recommendedOilType,
    String? licensePlate,
    String? vin,
    double? oilCapacity,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/vehicles'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'make': make,
          'model': model,
          'year': year,
          'vehicle_type': vehicleType,
          'recommended_oil_type': recommendedOilType,
          'license_plate': licensePlate,
          'vin': vin,
          'oil_capacity': oilCapacity,
          'is_default': isDefault,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final newVehicle = VehicleModel.fromJson(data['vehicle']);
        _vehicles.add(newVehicle);
        _error = null;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add vehicle');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing vehicle
  Future<bool> updateVehicle({
    required String vehicleId,
    required String make,
    required String model,
    required int year,
    required String vehicleType,
    required String recommendedOilType,
    String? licensePlate,
    String? vin,
    double? oilCapacity,
    bool? isDefault,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('${AppConstants.apiBaseUrl}/api/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'make': make,
          'model': model,
          'year': year,
          'vehicle_type': vehicleType,
          'recommended_oil_type': recommendedOilType,
          'license_plate': licensePlate,
          'vin': vin,
          'oil_capacity': oilCapacity,
          if (isDefault != null) 'is_default': isDefault,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedVehicle = VehicleModel.fromJson(data['vehicle']);

        final index = _vehicles.indexWhere((v) => v.id == vehicleId);
        if (index != -1) {
          _vehicles[index] = updatedVehicle;
        }

        _error = null;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update vehicle');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/api/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _vehicles.removeWhere((v) => v.id == vehicleId);
        _error = null;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete vehicle');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
