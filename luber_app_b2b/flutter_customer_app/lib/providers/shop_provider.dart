import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _shops = [];
  Map<String, dynamic>? _selectedShop;
  List<Map<String, dynamic>> _shopPackages = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get shops => _shops;
  Map<String, dynamic>? get selectedShop => _selectedShop;
  List<Map<String, dynamic>> get shopPackages => _shopPackages;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchNearbyShops(double latitude, double longitude, {double radiusMiles = 25}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('shops')
          .select('*')
          .eq('is_active', true)
          .eq('subscription_status', 'active');

      _shops = List<Map<String, dynamic>>.from(response as List);
      
      // TODO: Filter by distance using latitude/longitude
      // For now, showing all active shops
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectShop(String shopId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final shopResponse = await _supabase
          .from('shops')
          .select('*')
          .eq('id', shopId)
          .single();

      _selectedShop = shopResponse as Map<String, dynamic>;

      final packagesResponse = await _supabase
          .from('shop_service_packages')
          .select('*')
          .eq('shop_id', shopId)
          .eq('is_active', true);

      _shopPackages = List<Map<String, dynamic>>.from(packagesResponse as List);
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedShop = null;
    _shopPackages = [];
    notifyListeners();
  }
}
