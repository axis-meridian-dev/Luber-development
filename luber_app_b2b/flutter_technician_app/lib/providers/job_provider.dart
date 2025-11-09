import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
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

      final updatedJobs = (_shopTechnician!['total_jobs'] ?? 0) + 1;
      await _supabase
          .from('shop_technicians')
          .update({'total_jobs': updatedJobs})
          .eq('id', _shopTechnician!['id']);

      _shopTechnician = Map<String, dynamic>.from(_shopTechnician!)..['total_jobs'] = updatedJobs;

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

  Future<Map<String, dynamic>?> fetchJobDetails(String jobId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
            '''
            *,
            vehicle:vehicles(*),
            customer:customers(*, profile:profiles(*)),
            service_package:shop_service_packages(*),
            shop:shops(*),
            technician:shop_technicians(*, profile:profiles(*))
            ''',
          )
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchEarningsSummary() async {
    try {
      if (_shopTechnician == null) {
        await fetchShopTechnician();
      }

      if (_shopTechnician == null) {
        return {
          'totalEarnings': 0.0,
          'weekEarnings': 0.0,
          'pendingEarnings': 0.0,
          'completedJobs': 0,
          'activeJobs': 0,
          'recentPayouts': <Map<String, dynamic>>[],
        };
      }

      final response = await _supabase
          .from('bookings')
          .select('id,status,final_price,estimated_price,shop_payout,scheduled_date,completed_date')
          .eq('shop_technician_id', _shopTechnician!['id'])
          .order('scheduled_date', ascending: false);

      final bookings = List<Map<String, dynamic>>.from(response);

      double totalEarnings = 0;
      double weekEarnings = 0;
      double pendingEarnings = 0;
      int completedJobs = 0;
      int activeJobs = 0;
      final recentPayouts = <Map<String, dynamic>>[];

      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      for (final booking in bookings) {
        final status = booking['status'] as String;
        final amount = ((booking['shop_payout'] ?? booking['final_price'] ?? booking['estimated_price']) as num?)
                ?.toDouble() ??
            0;

        if (status == 'completed') {
          completedJobs += 1;
          totalEarnings += amount;
          final completedDate = booking['completed_date'] != null
              ? DateTime.parse(booking['completed_date'] as String)
              : DateTime.parse(booking['scheduled_date'] as String);
          if (!completedDate.isBefore(startOfWeek)) {
            weekEarnings += amount;
          }
          if (recentPayouts.length < 5) {
            recentPayouts.add(booking);
          }
        } else if (status == 'accepted' || status == 'in_progress') {
          activeJobs += 1;
          pendingEarnings += amount;
        }
      }

      return {
        'totalEarnings': totalEarnings,
        'weekEarnings': weekEarnings,
        'pendingEarnings': pendingEarnings,
        'completedJobs': completedJobs,
        'activeJobs': activeJobs,
        'recentPayouts': recentPayouts,
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'totalEarnings': 0.0,
        'weekEarnings': 0.0,
        'pendingEarnings': 0.0,
        'completedJobs': 0,
        'activeJobs': 0,
        'recentPayouts': <Map<String, dynamic>>[],
      };
    }
  }
}
