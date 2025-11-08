import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availableJobs = [];
  List<Map<String, dynamic>> _myJobs = [];
  Map<String, dynamic>? _shopTechnician;
  Map<String, dynamic>? _shop;
  bool _isLoading = false;
  bool _isAvailable = true;
  String? _error;

  List<Map<String, dynamic>> get availableJobs => _availableJobs;
  List<Map<String, dynamic>> get myJobs => _myJobs;
  Map<String, dynamic>? get shopTechnician => _shopTechnician;
  Map<String, dynamic>? get shop => _shop;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  String? get error => _error;

  Future<void> fetchShopTechnician() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('shop_technicians')
          .select('*, shops(*)')
          .eq('profile_id', user.id)
          .single();

      _shopTechnician = response as Map<String, dynamic>;
      _shop = _shopTechnician?['shops'] as Map<String, dynamic>?;
      _isAvailable = _shopTechnician?['is_available'] ?? true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAvailableJobs() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_shop == null) {
        await fetchShopTechnician();
      }

      if (_shop == null) {
        _availableJobs = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('bookings')
          .select('*, vehicles(*), customers(*, profiles(*)), shop_service_packages(*)')
          .eq('shop_id', _shop!['id'])
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _availableJobs = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyJobs() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_shopTechnician == null) {
        await fetchShopTechnician();
      }

      if (_shopTechnician == null) {
        _myJobs = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('bookings')
          .select('*, vehicles(*), customers(*, profiles(*)), shop_service_packages(*)')
          .eq('shop_technician_id', _shopTechnician!['id'])
          .order('scheduled_date', ascending: true);

      _myJobs = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptJob(String jobId) async {
    try {
      if (_shopTechnician == null) return false;

      await _supabase
          .from('bookings')
          .update({
            'shop_technician_id': _shopTechnician!['id'],
            'status': 'accepted',
          })
          .eq('id', jobId);

      await fetchAvailableJobs();
      await fetchMyJobs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', jobId);

      await fetchMyJobs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeJob(String jobId, double finalPrice) async {
    try {
      if (_shop == null || _shopTechnician == null) return false;

      // Calculate transaction fee based on shop tier
      final transactionFeePercent = _shop!['subscription_tier'] == 'solo' ? 0.08 : 0.05;
      final transactionFee = finalPrice * transactionFeePercent;
      final shopPayout = finalPrice - transactionFee;

      await _supabase
          .from('bookings')
          .update({
            'status': 'completed',
            'final_price': finalPrice,
            'transaction_fee': transactionFee,
            'shop_payout': shopPayout,
            'completed_date': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);

      // Update shop technician's total jobs count
      await _supabase
          .from('shop_technicians')
          .update({
            'total_jobs': (_shopTechnician!['total_jobs'] ?? 0) + 1,
          })
          .eq('id', _shopTechnician!['id']);

      await fetchMyJobs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleAvailability() async {
    try {
      if (_shopTechnician == null) return;

      _isAvailable = !_isAvailable;
      notifyListeners();

      await _supabase
          .from('shop_technicians')
          .update({'is_available': _isAvailable})
          .eq('id', _shopTechnician!['id']);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
