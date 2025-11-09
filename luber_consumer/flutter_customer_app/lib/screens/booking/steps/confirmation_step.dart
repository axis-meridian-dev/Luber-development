import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/payment_method_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/job_provider.dart';
import '../../../providers/payment_method_provider.dart';
import '../../../utils/pricing.dart';
import '../../payment_methods/add_payment_method_screen.dart';
import '../../payment_methods/payment_methods_screen.dart';

class ConfirmationStep extends StatefulWidget {
  final VoidCallback onBack;

  const ConfirmationStep({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends State<ConfirmationStep> {
  final _specialInstructionsController = TextEditingController();
  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaymentMethodProvider>().fetchPaymentMethods());
    // Pre-fill special instructions if any
    final bookingProvider = context.read<BookingProvider>();
    if (bookingProvider.specialInstructions != null) {
      _specialInstructionsController.text = bookingProvider.specialInstructions!;
    }
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _refreshPaymentMethods() async {
    await context.read<PaymentMethodProvider>().fetchPaymentMethods();
  }

  Future<void> _openAddPaymentMethod() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddPaymentMethodScreen(),
        fullscreenDialog: true,
      ),
    );
    if (added == true && mounted) {
      await _refreshPaymentMethods();
    }
  }

  Future<void> _openManagePaymentMethods() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
    if (mounted) {
      await _refreshPaymentMethods();
    }
  }

  void _syncPaymentSelection(
    PaymentMethodProvider paymentProvider,
    BookingProvider bookingProvider,
  ) {
    final methods = paymentProvider.paymentMethods;
    if (methods.isEmpty) {
      if (bookingProvider.selectedPaymentMethod != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          bookingProvider.clearPaymentMethod();
        });
      }
      return;
    }

    final current = bookingProvider.selectedPaymentMethod;
    final hasCurrent = current != null && methods.any((method) => method.id == current.id);
    if (!hasCurrent) {
      final next = paymentProvider.defaultMethod ?? methods.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bookingProvider.selectPaymentMethod(next);
      });
    }
  }

  Future<void> _confirmBooking() async {
    final bookingProvider = context.read<BookingProvider>();

    // Validate all selections
    if (!bookingProvider.isBookingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all booking steps'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save special instructions
      final instructions = _specialInstructionsController.text.trim();
      if (instructions.isNotEmpty) {
        bookingProvider.setSpecialInstructions(instructions);
      }

      // Create booking via JobProvider
      final jobProvider = context.read<JobProvider>();
      final job = await jobProvider.createJob(
        vehicleId: bookingProvider.selectedVehicle!.id,
        addressId: bookingProvider.selectedAddress!.id,
        oilType: bookingProvider.selectedOilType!,
        latitude: bookingProvider.selectedAddress!.latitude ?? 0.0,
        longitude: bookingProvider.selectedAddress!.longitude ?? 0.0,
        scheduledFor: bookingProvider.scheduledDateTime!,
        paymentMethodId: bookingProvider.selectedPaymentMethod!.stripePaymentMethodId,
      );

      if (job != null) {
        if (!mounted) return;

        // Reset booking state
        bookingProvider.reset();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed! Finding a technician...'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to active job screen
        Navigator.of(context).pushReplacementNamed(
          '/active-job',
          arguments: job.id,
        );
      } else {
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final paymentProvider = context.watch<PaymentMethodProvider>();
    _syncPaymentSelection(paymentProvider, bookingProvider);

    final dateFormatter = DateFormat('EEEE, MMMM d, y');
    final timeFormatter = DateFormat('h:mm a');

    final selectedVehicle = bookingProvider.selectedVehicle;
    final selectedAddress = bookingProvider.selectedAddress;
    final selectedOilType = bookingProvider.selectedOilType;
    final scheduledDateTime = bookingProvider.scheduledDateTime;
    final selectedPaymentMethod = bookingProvider.selectedPaymentMethod;
    final paymentMethods = paymentProvider.paymentMethods;

    // Calculate pricing using actual vehicle type
    final vehicleType = selectedVehicle?.vehicleType ?? 'sedan';
    final pricing = selectedOilType != null
        ? calculateJobPrice(selectedOilType, vehicleType)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review and confirm',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Summary
                _buildSummaryCard(
                  title: 'Vehicle',
                  icon: Icons.directions_car,
                  content: selectedVehicle?.displayName ?? 'Not selected',
                  subtitle: selectedVehicle?.color,
                ),
                const SizedBox(height: 12),
                // Address Summary
                _buildSummaryCard(
                  title: 'Location',
                  icon: Icons.location_on,
                  content: selectedAddress?.label ?? 'Not selected',
                  subtitle: selectedAddress?.fullAddress,
                ),
                const SizedBox(height: 12),
                // Service Summary
                _buildSummaryCard(
                  title: 'Service',
                  icon: Icons.local_gas_station,
                  content: selectedOilType != null
                      ? getOilTypeName(selectedOilType)
                      : 'Not selected',
                  subtitle: pricing?.priceFormatted,
                ),
                const SizedBox(height: 12),
                // Schedule Summary
                _buildSummaryCard(
                  title: 'Scheduled',
                  icon: Icons.calendar_today,
                  content: scheduledDateTime != null
                      ? dateFormatter.format(scheduledDateTime)
                      : 'Not selected',
                  subtitle: scheduledDateTime != null
                      ? timeFormatter.format(scheduledDateTime)
                      : null,
                ),
                const SizedBox(height: 12),
                // Payment Method Summary
                _buildSummaryCard(
                  title: 'Payment',
                  icon: Icons.credit_card,
                  content: selectedPaymentMethod?.displayName ?? 'Not selected',
                  subtitle: selectedPaymentMethod != null
                      ? (selectedPaymentMethod.isDefault ? 'Default card' : 'Selected card')
                      : null,
                  trailing: TextButton(
                    onPressed: paymentProvider.isLoading
                        ? null
                        : (paymentMethods.isEmpty ? _openAddPaymentMethod : _openManagePaymentMethods),
                    child: Text(paymentMethods.isEmpty ? 'Add Card' : 'Manage'),
                  ),
                ),
                const SizedBox(height: 16),
                // Special Instructions
                TextField(
                  controller: _specialInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Special instructions (optional)',
                    hintText: 'e.g., Park in driveway, Gate code is 1234',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    bookingProvider.setSpecialInstructions(value.trim());
                  },
                ),
                const SizedBox(height: 16),
                // Price Breakdown
                if (pricing != null) ...[
                  Card(
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Price Breakdown',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow('Service', pricing.priceFormatted),
                          const Divider(height: 24),
                          _buildPriceRow(
                            'Total',
                            pricing.priceFormatted,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Terms and Conditions
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                  title: const Text(
                    'I agree to the terms and conditions',
                    style: TextStyle(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : widget.onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required String content,
    String? subtitle,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
