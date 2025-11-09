import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? _booking;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.fetchBookingDetails(widget.bookingId);

    if (!mounted) return;

    setState(() {
      _booking = booking;
      _loading = false;
      _error = booking == null ? 'Booking not found' : null;
    });
  }

  Future<void> _cancelBooking() async {
    if (_booking == null) return;
    setState(() {
      _actionLoading = true;
    });
    final bookingProvider = context.read<BookingProvider>();
    final success = await bookingProvider.cancelBooking(widget.bookingId);

    if (!mounted) return;

    setState(() {
      _actionLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
      await _loadBooking();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingProvider.error ?? 'Unable to cancel booking')),
      );
    }
  }

  bool get _canCancel {
    final status = _booking?['status'] as String?;
    return status == 'pending' || status == 'accepted';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadBooking,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusCard(context),
                      const SizedBox(height: 16),
                      _buildScheduleCard(context),
                      const SizedBox(height: 16),
                      _buildServiceCard(context),
                      const SizedBox(height: 16),
                      _buildVehicleCard(context),
                      const SizedBox(height: 16),
                      _buildTechnicianCard(context),
                      if (_canCancel) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _actionLoading ? null : _cancelBooking,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _actionLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Cancel Booking'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _booking!['status'] as String;
    final scheduledDate = DateTime.parse(_booking!['scheduled_date'] as String);
    final formatter = DateFormat('MMM d, y • h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: CircleAvatar(
                backgroundColor: _statusColor(status).withOpacity(0.15),
                child: Icon(Icons.local_shipping, size: 16, color: _statusColor(status)),
              ),
              label: Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600),
              ),
              backgroundColor: _statusColor(status).withOpacity(0.1),
              side: BorderSide.none,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(formatter.format(scheduledDate)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.confirmation_number, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking ID: ${_booking!['id'].toString().substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final shop = _booking!['shop'] as Map<String, dynamic>?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_booking!['service_address']}\n'
                    '${_booking!['service_city']}, ${_booking!['service_state']} ${_booking!['service_zip']}',
                  ),
                ),
              ],
            ),
            if (_booking!['notes'] != null && (_booking!['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _booking!['notes'] as String,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
            if (shop != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text((shop['shop_name'] as String).substring(0, 1).toUpperCase()),
                ),
                title: Text(shop['shop_name'] as String),
                subtitle: Text('${shop['business_city']}, ${shop['business_state']}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context) {
    final package = _booking!['service_package'] as Map<String, dynamic>?;
    final price = (_booking!['final_price'] ?? _booking!['estimated_price']) as num?;
    final payout = _booking!['shop_payout'] as num?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_booking!['service_type'] as String),
              subtitle: package != null ? Text(package['description'] ?? '') : null,
              trailing: price != null
                  ? Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  : null,
            ),
            if (package != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${package['estimated_duration_minutes']} min')),
                  if (package['oil_brand'] != null) Chip(label: Text(package['oil_brand'] as String)),
                  if (package['oil_type'] != null) Chip(label: Text(package['oil_type'] as String)),
                  if (package['includes_filter'] == true) const Chip(label: Text('Filter Included')),
                  if (package['includes_inspection'] == true) const Chip(label: Text('Inspection Included')),
                ],
              ),
            if (payout != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shop Payout', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '\$${payout.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context) {
    final vehicle = _booking!['vehicle'] as Map<String, dynamic>?;
    if (vehicle == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text('${vehicle['year']} ${vehicle['make']} ${vehicle['model']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle['color'] != null) Text('Color: ${vehicle['color']}'),
            if (vehicle['license_plate'] != null) Text('Plate: ${vehicle['license_plate']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianCard(BuildContext context) {
    final technician = _booking!['technician'] as Map<String, dynamic>?;
    final profile = technician?['profile'] as Map<String, dynamic>?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Technician',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (technician == null)
              Text(
                'A technician will be assigned soon.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      (profile?['full_name'] ?? 'Tech').toString().substring(0, 1).toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?['full_name'] ?? 'Assigned Technician',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (profile?['phone'] != null)
                          Text(
                            profile!['phone'] as String,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        Text(
                          technician['is_available'] == true ? 'Available' : 'Offline',
                          style: TextStyle(color: technician['is_available'] == true ? Colors.green : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
