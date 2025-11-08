import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';

class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: Get user's actual location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().fetchNearbyShops(37.7749, -122.4194);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Shop'),
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          if (shopProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shopProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${shopProvider.error}'),
                  ElevatedButton(
                    onPressed: () {
                      shopProvider.fetchNearbyShops(37.7749, -122.4194);
                    },
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
                      Text(
                        '${shop['total_technicians']} technicians • ${shop['service_radius_miles']} mile radius',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    await shopProvider.selectShop(shop['id']);
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/shop-services');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
