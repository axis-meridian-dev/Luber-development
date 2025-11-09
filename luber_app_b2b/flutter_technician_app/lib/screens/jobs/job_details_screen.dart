import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  Map<String, dynamic>? _job;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<JobProvider>();
    final job = await provider.fetchJobDetails(widget.jobId);
    if (!mounted) return;
    setState(() {
      _job = job;
      _loading = false;
      _error = job == null ? 'Job not found' : null;
    });
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _actionLoading = true;
    });
    final provider = context.read<JobProvider>();
    final success = await provider.updateJobStatus(widget.jobId, status);
    if (!mounted) return;
    setState(() {
      _actionLoading = false;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.replaceAll('_', ' ')}')),
      );
      await _loadJob();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Unable to update job')),
      );
    }
  }

  Future<void> _completeJob() async {
    final controller = TextEditingController(
      text: ((_job?['final_price'] ?? _job?['estimated_price']) as num?)?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Job'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Final Price',
                prefixText: '\$',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter final price';
                return double.tryParse(value) == null ? 'Enter a valid number' : null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, double.parse(controller.text));
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      _actionLoading = true;
    });

    final provider = context.read<JobProvider>();
    final success = await provider.completeJob(widget.jobId, result);
    if (!mounted) return;

    setState(() {
      _actionLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job completed')),
      );
      await _loadJob();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Unable to complete job')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadJob,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusCard(context),
                      const SizedBox(height: 16),
                      _buildCustomerCard(context),
                      const SizedBox(height: 16),
                      _buildVehicleCard(context),
                      const SizedBox(height: 16),
                      _buildServiceCard(context),
                      const SizedBox(height: 16),
                      _buildLocationCard(context),
                      const SizedBox(height: 24),
                      _buildActions(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _job!['status'] as String;
    final scheduledDate = DateTime.parse(_job!['scheduled_date'] as String);
    final formatter = DateFormat('MMM d, h:mm a');
    final statusColor = _statusColor(status);

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
              label: Text(status.replaceAll('_', ' ').toUpperCase()),
              backgroundColor: statusColor.withOpacity(0.1),
              labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Text(formatter.format(scheduledDate)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.confirmation_number),
                const SizedBox(width: 8),
                Text('Job #${_job!['id'].toString().substring(0, 8)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final customer = _job!['customer'] as Map<String, dynamic>?;
    final profile = customer?['profile'] as Map<String, dynamic>?;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(profile?['full_name'] ?? 'Customer'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile?['phone'] != null) Text(profile!['phone']),
            if (customer?['preferred_payment_method'] != null)
              Text('Prefers ${customer!['preferred_payment_method']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context) {
    final vehicle = _job!['vehicle'] as Map<String, dynamic>?;
    if (vehicle == null) return const SizedBox.shrink();
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

  Widget _buildServiceCard(BuildContext context) {
    final package = _job!['service_package'] as Map<String, dynamic>?;
    final price = (_job!['final_price'] ?? _job!['estimated_price']) as num?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_job!['service_type'] as String),
              subtitle: package != null ? Text(package['description'] ?? '') : null,
              trailing: price != null
                  ? Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
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
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_job!['service_address']}\n'
                    '${_job!['service_city']}, ${_job!['service_state']} ${_job!['service_zip']}',
                  ),
                ),
              ],
            ),
            if (_job!['notes'] != null && (_job!['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _job!['notes'] as String,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final status = _job!['status'] as String;
    if (status == 'completed' || status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (status == 'accepted')
          FilledButton.icon(
            onPressed: _actionLoading ? null : () => _updateStatus('in_progress'),
            icon: _actionLoading ? const SizedBox.shrink() : const Icon(Icons.play_arrow),
            label: _actionLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Start Job'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        if (status == 'in_progress') ...[
          FilledButton.icon(
            onPressed: _actionLoading ? null : _completeJob,
            icon: _actionLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle),
            label: _actionLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Complete Job'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _actionLoading ? null : () => _updateStatus('accepted'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Revert to Accepted'),
          ),
        ],
      ],
    );
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
}
