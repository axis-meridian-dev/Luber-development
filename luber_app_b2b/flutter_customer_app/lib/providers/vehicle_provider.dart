import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get vehicles => _vehicles;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchVehicles() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _vehicles = [];
        return;
      }

      final response = await _supabase
          .from('vehicles')
          .select('*')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      _vehicles = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> addVehicle({
    required String make,
    required String model,
    required int year,
    required String vehicleType,
    String? color,
    String? licensePlate,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final vehicle = await _supabase
          .from('vehicles')
          .insert({
            'customer_id': user.id,
            'make': make,
            'model': model,
            'year': year,
            'vehicle_type': vehicleType,
            'color': color,
            'license_plate': licensePlate,
            'notes': notes,
          })
          .select()
          .single();

      _vehicles = [vehicle as Map<String, dynamic>, ..._vehicles];
      notifyListeners();
      return vehicle['id'] as String?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _supabase.from('vehicles').delete().eq('id', vehicleId);
      _vehicles = _vehicles.where((vehicle) => vehicle['id'] != vehicleId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
