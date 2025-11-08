import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';

class ShopServicesScreen extends StatelessWidget {
  const ShopServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ShopProvider>(
          builder: (context, shopProvider, child) {
            return Text(shopProvider.selectedShop?['shop_name'] ?? 'Services');
          },
        ),
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          if (shopProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final shop = shopProvider.selectedShop;
          final packages = shopProvider.shopPackages;

          if (shop == null) {
            return const Center(child: Text('No shop selected'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Header with branding
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(int.parse(shop['primary_color'].substring(1), radix: 16) + 0xFF000000),
                  ),
                  child: Column(
                    children: [
                      if (shop['logo_url'] != null)
                        Image.network(
                          shop['logo_url'],
                          height: 80,
                        )
                      else
                        CircleAvatar(
                          radius: 40,
                          child: Text(
                            shop['shop_name'][0].toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        shop['shop_name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${shop['business_city']}, ${shop['business_state']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Service Packages
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose a Service Package',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (packages.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No service packages available'),
                          ),
                        )
                      else
                        ...packages.map((package) => Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/new-booking',
                                    arguments: {
                                      'shop': shop,
                                      'package': package,
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              package['package_name'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '\$${package['price']}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(int.parse(shop['primary_color'].substring(1), radix: 16) + 0xFF000000),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (package['description'] != null)
                                        Text(
                                          package['description'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (package['oil_brand'] != null)
                                            Chip(
                                              label: Text(package['oil_brand']),
                                              backgroundColor: Colors.blue[50],
                                            ),
                                          if (package['oil_type'] != null)
                                            Chip(
                                              label: Text(package['oil_type']),
                                              backgroundColor: Colors.green[50],
                                            ),
                                          if (package['includes_filter'])
                                            const Chip(
                                              label: Text('Includes Filter'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          if (package['includes_inspection'])
                                            const Chip(
                                              label: Text('Includes Inspection'),
                                              backgroundColor: Colors.purple,
                                            ),
                                          Chip(
                                            label: Text('${package['estimated_duration_minutes']} min'),
                                            backgroundColor: Colors.grey[200],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
