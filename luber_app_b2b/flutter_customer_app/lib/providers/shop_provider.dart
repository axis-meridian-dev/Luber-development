import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/location_service.dart';

class ShopProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService();

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

      List<Map<String, dynamic>> allShops = List<Map<String, dynamic>>.from(response as List);

      // Calculate distance for each shop and filter by radius
      List<Map<String, dynamic>> nearbyShops = [];

      for (var shop in allShops) {
        // Assuming shops table has latitude/longitude fields
        // If not, you may need to geocode the business_address
        final shopLat = shop['business_latitude'] as double?;
        final shopLon = shop['business_longitude'] as double?;

        if (shopLat != null && shopLon != null) {
          final distance = _locationService.calculateDistance(
            latitude,
            longitude,
            shopLat,
            shopLon,
          );

          // Only include shops within the specified radius
          if (distance <= radiusMiles) {
            shop['distance'] = distance;
            nearbyShops.add(shop);
          }
        } else {
          // If shop doesn't have coordinates, include it but mark distance as unknown
          shop['distance'] = null;
          nearbyShops.add(shop);
        }
      }

      // Sort by distance (nearest first), null distances at the end
      nearbyShops.sort((a, b) {
        final distA = a['distance'] as double?;
        final distB = b['distance'] as double?;

        if (distA == null && distB == null) return 0;
        if (distA == null) return 1;
        if (distB == null) return -1;

        return distA.compareTo(distB);
      });

      _shops = nearbyShops;

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
