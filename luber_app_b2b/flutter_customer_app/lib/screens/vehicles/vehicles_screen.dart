import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vehicle_provider.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  Future<void> _showAddVehicleSheet() async {
    final formKey = GlobalKey<FormState>();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final colorController = TextEditingController();
    final plateController = TextEditingController();
    String vehicleType = 'sedan';

    final provider = context.read<VehicleProvider>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Vehicle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: makeController,
                  decoration: const InputDecoration(labelText: 'Make'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed < 1990) return 'Enter a valid year';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  items: const [
                    DropdownMenuItem(value: 'sedan', child: Text('Sedan')),
                    DropdownMenuItem(value: 'suv', child: Text('SUV')),
                    DropdownMenuItem(value: 'truck', child: Text('Truck')),
                    DropdownMenuItem(value: 'van', child: Text('Van')),
                    DropdownMenuItem(value: 'sports', child: Text('Sports Car')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      vehicleType = value;
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Vehicle Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'License Plate (optional)'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final year = int.parse(yearController.text.trim());
                          final id = await provider.addVehicle(
                            make: makeController.text.trim(),
                            model: modelController.text.trim(),
                            year: year,
                            vehicleType: vehicleType,
                            color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
                            licensePlate: plateController.text.trim().isEmpty ? null : plateController.text.trim(),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context, id != null);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          if (vehicleProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vehicleProvider.vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No vehicles yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first vehicle to book services faster.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showAddVehicleSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vehicleProvider.fetchVehicles,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: vehicleProvider.vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vehicle = vehicleProvider.vehicles[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('${vehicle['year']} ${vehicle['make']} ${vehicle['model']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (vehicle['vehicle_type'] as String?)?.toUpperCase() ?? 'SEDAN',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (vehicle['license_plate'] != null)
                          Text('Plate: ${vehicle['license_plate']}', style: TextStyle(color: Colors.grey[600])),
                        if (vehicle['color'] != null)
                          Text('Color: ${vehicle['color']}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await vehicleProvider.deleteVehicle(vehicle['id'] as String);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vehicle removed')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
