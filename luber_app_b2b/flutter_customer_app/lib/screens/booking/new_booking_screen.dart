import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/vehicle_provider.dart';

class NewBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedShop;
  final Map<String, dynamic>? selectedPackage;

  const NewBookingScreen({
    super.key,
    this.selectedShop,
    this.selectedPackage,
  });

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedVehicleId;
  Map<String, dynamic>? _shop;
  Map<String, dynamic>? _servicePackage;

  @override
  void initState() {
    super.initState();
    _shop = widget.selectedShop;
    _servicePackage = widget.selectedPackage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasSelection => _shop != null && _servicePackage != null;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a shop and package first.')),
      );
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle to your account before booking.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final bookingProvider = context.read<BookingProvider>();
    final package = _servicePackage!;
    final shop = _shop!;
    final price = (package['price'] as num).toDouble();

    final success = await bookingProvider.createBooking(
      vehicleId: _selectedVehicleId!,
      serviceType: package['package_name'] as String,
      scheduledDate: scheduledDateTime,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zip: _zipController.text.trim(),
      shopId: shop['id'] as String,
      servicePackageId: package['id'] as String,
      price: price,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.error ?? 'Failed to create booking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Change Shop',
            onPressed: () => context.go('/shop-selection'),
          ),
        ],
      ),
      body: !_hasSelection ? _buildMissingSelection(context) : _buildBookingForm(context),
    );
  }

  Widget _buildMissingSelection(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Choose a service package first',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a shop and package to continue with booking.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/shop-selection'),
              child: const Text('Browse Shops'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSelectionSummary(context),
          const SizedBox(height: 24),
          _buildVehicleSection(context),
          const SizedBox(height: 24),
          _buildScheduleSection(context),
          const SizedBox(height: 24),
          _buildLocationSection(context),
          const SizedBox(height: 24),
          _buildNotesSection(context),
          const SizedBox(height: 32),
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              return FilledButton(
                onPressed: bookingProvider.isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: bookingProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm Booking'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    final shop = _shop!;
    final package = _servicePackage!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Shop',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                (shop['shop_name'] as String).substring(0, 1).toUpperCase(),
              ),
            ),
            title: Text(shop['shop_name'] as String),
            subtitle: Text('${shop['business_city']}, ${shop['business_state']}'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Service Package',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
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
                        package['package_name'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '\$${package['price']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (package['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    package['description'] as String,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text('${package['estimated_duration_minutes']} min'),
                    ),
                    if (package['oil_brand'] != null)
                      Chip(
                        label: Text(package['oil_brand'] as String),
                      ),
                    if (package['oil_type'] != null)
                      Chip(
                        label: Text((package['oil_type'] as String).toString().toUpperCase()),
                      ),
                    if (package['includes_filter'] == true)
                      const Chip(
                        label: Text('Filter Included'),
                      ),
                    if (package['includes_inspection'] == true)
                      const Chip(
                        label: Text('Inspection Included'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, child) {
            if (vehicleProvider.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vehicleProvider.vehicles.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No vehicles found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a vehicle to complete your booking.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          await context.push('/vehicles');
                          if (mounted) {
                            await vehicleProvider.fetchVehicles();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Vehicle'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_selectedVehicleId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedVehicleId = vehicleProvider.vehicles.first['id'] as String;
                });
              });
            }

            return Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: vehicleProvider.vehicles
                      .map(
                        (vehicle) => DropdownMenuItem(
                          value: vehicle['id'] as String,
                          child: Text(
                            '${vehicle['year']} ${vehicle['make']} ${vehicle['model']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedVehicleId = value;
                  }),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a vehicle';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await context.push('/vehicles');
                      if (mounted) {
                        await vehicleProvider.fetchVehicles();
                      }
                    },
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Manage Vehicles'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  '${_selectedTime.format(context)}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Street Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _zipController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ZIP Code',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a ZIP code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Any special instructions or requests...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
