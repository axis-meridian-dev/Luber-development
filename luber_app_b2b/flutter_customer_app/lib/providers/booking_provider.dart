import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _bookings = [];
        return;
      }

      final response = await _supabase
          .from('bookings')
          .select(
            '''
            *,
            vehicle:vehicles(*),
            shop:shops(*),
            service_package:shop_service_packages(*),
            customer:customers(*, profile:profiles(*)),
            technician:shop_technicians(*, profile:profiles(*))
            ''',
          )
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      _bookings = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking({
    required String vehicleId,
    required String serviceType,
    required DateTime scheduledDate,
    required String address,
    required String city,
    required String state,
    required String zip,
    required String shopId,
    required String servicePackageId,
    required double price,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('bookings').insert({
        'customer_id': user.id,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        'scheduled_date': scheduledDate.toIso8601String(),
        'service_address': address,
        'service_city': city,
        'service_state': state,
        'service_zip': zip,
        'service_latitude': latitude,
        'service_longitude': longitude,
        'notes': notes,
        'status': 'pending',
        'shop_id': shopId,
        'service_package_id': servicePackageId,
        'estimated_price': price,
      });

      await fetchBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({'status': 'cancelled'}).eq('id', bookingId);
      await fetchBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchBookingDetails(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
            '''
            *,
            vehicle:vehicles(*),
            shop:shops(*),
            service_package:shop_service_packages(*),
            customer:customers(*, profile:profiles(*)),
            technician:shop_technicians(*, profile:profiles(*))
            ''',
          )
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
