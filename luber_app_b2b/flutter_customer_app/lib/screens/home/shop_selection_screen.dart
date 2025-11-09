import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/location_service.dart';

class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  final LocationService _locationService = LocationService();
  bool _locationLoading = true;
  bool _locationPermissionDenied = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadShopsWithLocation();
  }

  Future<void> _loadShopsWithLocation() async {
    setState(() {
      _locationLoading = true;
      _locationPermissionDenied = false;
      _locationError = null;
    });

    try {
      // Get user's current location
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        if (mounted) {
          await context.read<ShopProvider>().fetchNearbyShops(
                position.latitude,
                position.longitude,
              );
        }
      } else {
        // Location permission denied or services disabled
        setState(() {
          _locationPermissionDenied = true;
          _locationError = 'Location permission denied or services disabled';
        });

        // Fall back to showing all shops without distance filtering
        if (mounted) {
          // Use default coordinates (e.g., city center) as fallback
          await context.read<ShopProvider>().fetchNearbyShops(37.7749, -122.4194);
        }
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
      });

      // Fall back to showing all shops
      if (mounted) {
        await context.read<ShopProvider>().fetchNearbyShops(37.7749, -122.4194);
      }
    } finally {
      setState(() {
        _locationLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _locationService.hasLocationPermission();
    if (!hasPermission) {
      await _locationService.openAppSettings();
    }
    _loadShopsWithLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Shop'),
      ),
      body: Column(
        children: [
          // Location permission banner
          if (_locationPermissionDenied)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Location access needed for accurate results',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestLocationPermission,
                    child: const Text('Enable'),
                  ),
                ],
              ),
            ),

          // Shop list
          Expanded(
            child: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                if (_locationLoading || shopProvider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (shopProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${shopProvider.error}'),
                        ElevatedButton(
                          onPressed: _loadShopsWithLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (shopProvider.shops.isEmpty) {
                  return const Center(
                    child: Text('No shops available in your area'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shopProvider.shops.length,
                  itemBuilder: (context, index) {
                    final shop = shopProvider.shops[index];
                    final distance = shop['distance'] as double?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: shop['logo_url'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(shop['logo_url']),
                              )
                            : CircleAvatar(
                                child: Text(shop['shop_name'][0].toUpperCase()),
                              ),
                        title: Text(
                          shop['shop_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${shop['business_city']}, ${shop['business_state']}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (distance != null) ...[
                                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _locationService.formatDistance(distance),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('•', style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '${shop['total_technicians']} technicians',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          await shopProvider.selectShop(shop['id']);
                          if (!context.mounted) return;
                          if (shopProvider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(shopProvider.error!)),
                            );
                            return;
                          }
                          context.push('/shop-services');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
