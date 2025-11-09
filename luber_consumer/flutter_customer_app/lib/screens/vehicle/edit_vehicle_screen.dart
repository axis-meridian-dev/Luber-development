import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../models/vehicle_model.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const EditVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _vinController;
  late final TextEditingController _oilCapacityController;

  late String _selectedVehicleType;
  late String _selectedOilType;
  late bool _isDefault;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'sedan', 'label': 'Sedan', 'icon': Icons.directions_car},
    {'value': 'suv', 'label': 'SUV', 'icon': Icons.airport_shuttle},
    {'value': 'truck', 'label': 'Truck', 'icon': Icons.local_shipping},
    {'value': 'sports_car', 'label': 'Sports Car', 'icon': Icons.sports_score},
    {'value': 'hybrid', 'label': 'Hybrid', 'icon': Icons.electric_car},
    {'value': 'electric', 'label': 'Electric', 'icon': Icons.ev_station},
  ];

  final List<Map<String, String>> _oilTypes = [
    {'value': 'conventional', 'label': 'Conventional'},
    {'value': 'synthetic_blend', 'label': 'Synthetic Blend'},
    {'value': 'full_synthetic', 'label': 'Full Synthetic'},
    {'value': 'high_mileage', 'label': 'High Mileage'},
  ];

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.vehicle.make);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _yearController = TextEditingController(text: widget.vehicle.year.toString());
    _licensePlateController = TextEditingController(text: widget.vehicle.licensePlate ?? '');
    _vinController = TextEditingController(text: widget.vehicle.vin ?? '');
    _oilCapacityController = TextEditingController(
      text: widget.vehicle.oilCapacity?.toString() ?? '',
    );
    _selectedVehicleType = widget.vehicle.vehicleType;
    _selectedOilType = widget.vehicle.recommendedOilType;
    _isDefault = widget.vehicle.isDefault;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _oilCapacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
        backgroundColor: const Color(0xFF0070F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _makeController,
              decoration: const InputDecoration(
                labelText: 'Make *',
                hintText: 'e.g., Toyota, Honda, Ford',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle make';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model *',
                hintText: 'e.g., Camry, Civic, F-150',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle model';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year *',
                hintText: 'e.g., 2024',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle year';
                }
                final year = int.tryParse(value);
                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Vehicle Type *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _vehicleTypes.map((type) {
                final isSelected = _selectedVehicleType == type['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(type['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedVehicleType = type['value'] as String;
                    });
                  },
                  selectedColor: const Color(0xFF0070F3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recommended Oil Type *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedOilType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
              items: _oilTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOilType = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Optional Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: 'License Plate',
                hintText: 'ABC-1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vinController,
              decoration: const InputDecoration(
                labelText: 'VIN',
                hintText: '17-character VIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(17),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length != 17) {
                  return 'VIN must be 17 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oilCapacityController,
              decoration: const InputDecoration(
                labelText: 'Oil Capacity (quarts)',
                hintText: 'e.g., 5.0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.opacity),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final capacity = double.tryParse(value);
                  if (capacity == null || capacity <= 0 || capacity > 20) {
                    return 'Please enter a valid oil capacity (0-20 quarts)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as default vehicle'),
              subtitle: const Text('Use this vehicle for quick bookings'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
              activeColor: const Color(0xFF0070F3),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _updateVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isDeleting ? null : _confirmDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Text(
                      'Delete Vehicle',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final vehicleProvider = context.read<VehicleProvider>();

    final success = await vehicleProvider.updateVehicle(
      vehicleId: widget.vehicle.id,
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      vehicleType: _selectedVehicleType,
      recommendedOilType: _selectedOilType,
      licensePlate: _licensePlateController.text.trim().isEmpty
          ? null
          : _licensePlateController.text.trim(),
      vin: _vinController.text.trim().isEmpty
          ? null
          : _vinController.text.trim(),
      oilCapacity: _oilCapacityController.text.trim().isEmpty
          ? null
          : double.parse(_oilCapacityController.text.trim()),
      isDefault: _isDefault,
    );

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vehicleProvider.error ?? 'Failed to update vehicle'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete ${widget.vehicle.displayName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteVehicle();
    }
  }

  Future<void> _deleteVehicle() async {
    setState(() {
      _isDeleting = true;
    });

    final vehicleProvider = context.read<VehicleProvider>();
    final success = await vehicleProvider.deleteVehicle(widget.vehicle.id);

    setState(() {
      _isDeleting = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vehicleProvider.error ?? 'Failed to delete vehicle'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
