import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../utils/pricing.dart';

class ServiceStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ServiceStep({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ServiceStep> createState() => _ServiceStepState();
}

class _ServiceStepState extends State<ServiceStep> {
  final List<String> _oilTypes = [
    'conventional',
    'synthetic_blend',
    'full_synthetic',
    'high_mileage',
  ];

  void _selectOilType(String oilType) {
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.selectOilType(oilType);
  }

  void _handleNext() {
    final bookingProvider = context.read<BookingProvider>();
    if (bookingProvider.selectedOilType != null) {
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an oil type'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  IconData _getOilTypeIcon(String oilType) {
    switch (oilType) {
      case 'conventional':
        return Icons.local_gas_station;
      case 'synthetic_blend':
        return Icons.science;
      case 'full_synthetic':
        return Icons.stars;
      case 'high_mileage':
        return Icons.speed;
      default:
        return Icons.local_gas_station;
    }
  }

  Color _getOilTypeColor(String oilType) {
    switch (oilType) {
      case 'conventional':
        return Colors.blue;
      case 'synthetic_blend':
        return Colors.purple;
      case 'full_synthetic':
        return Colors.amber;
      case 'high_mileage':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final selectedVehicle = bookingProvider.selectedVehicle;

    // Get vehicle type from selected vehicle
    final vehicleType = selectedVehicle?.vehicleType ?? 'sedan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select oil type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (selectedVehicle != null) ...[
          const SizedBox(height: 8),
          Text(
            'For: ${selectedVehicle.displayName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _oilTypes.length,
            itemBuilder: (context, index) {
              final oilType = _oilTypes[index];
              final isSelected = bookingProvider.selectedOilType == oilType;
              final pricing = calculateJobPrice(oilType, vehicleType);
              final icon = _getOilTypeIcon(oilType);
              final color = _getOilTypeColor(oilType);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => _selectOilType(oilType),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            size: 32,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getOilTypeName(oilType),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                getOilTypeDescription(oilType),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pricing.priceFormatted,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Info card about pricing
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Prices include oil, filter, and service. Pricing may vary based on vehicle type.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleNext,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
