import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/address_model.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../address/address_form_screen.dart';
import '../../address/addresses_screen.dart';

class AddressStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AddressStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AddressProvider>().fetchAddresses());
  }

  Future<void> _openAddressForm([AddressModel? address]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(address: address),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      await context.read<AddressProvider>().fetchAddresses();
    }
  }

  Future<void> _openAddressManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressesScreen()),
    );
    if (mounted) {
      await context.read<AddressProvider>().fetchAddresses();
    }
  }

  void _selectAddress(AddressModel address) {
    context.read<BookingProvider>().selectAddress(address);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final addressProvider = context.watch<AddressProvider>();

    if (addressProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (addressProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text('Unable to load addresses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              addressProvider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => addressProvider.fetchAddresses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final addresses = addressProvider.addresses;

    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No saved addresses', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a service location to continue',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddressForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070F3),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openAddressManager,
              child: const Text('Manage addresses'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where should we service your vehicle?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Select a saved location or add a new address.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isSelected = bookingProvider.selectedAddress?.id == address.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  onTap: () => _selectAddress(address),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.15)
                        : Colors.grey[200],
                    child: Icon(
                      Icons.location_on,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(address.fullAddress),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openAddressForm(address),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openAddressForm,
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
        ),
        TextButton(
          onPressed: _openAddressManager,
          child: const Text('Manage all addresses'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
