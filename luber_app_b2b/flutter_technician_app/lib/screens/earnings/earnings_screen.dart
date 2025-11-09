import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<Map<String, dynamic>> _summaryFuture;
  final _currency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<Map<String, dynamic>> _loadSummary() {
    return context.read<JobProvider>().fetchEarningsSummary();
  }

  Future<void> _refresh() async {
    final future = _loadSummary();
    setState(() {
      _summaryFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load earnings: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final payouts = List<Map<String, dynamic>>.from(data['recentPayouts'] as List);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryGrid(context, data),
                const SizedBox(height: 24),
                Text(
                  'Recent Payouts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (payouts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No payouts yet. Complete jobs to see earnings here.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...payouts.map((booking) => _buildPayoutTile(context, booking)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, Map<String, dynamic> data) {
    final cards = [
      _SummaryCard(
        title: 'Total Earned',
        value: _currency.format(data['totalEarnings']),
        subtitle: 'All time',
        icon: Icons.payments,
        color: Colors.indigo,
      ),
      _SummaryCard(
        title: 'This Week',
        value: _currency.format(data['weekEarnings']),
        subtitle: 'Completed jobs',
        icon: Icons.calendar_today,
        color: Colors.green,
      ),
      _SummaryCard(
        title: 'Pending',
        value: _currency.format(data['pendingEarnings']),
        subtitle: 'Accepted & in-progress',
        icon: Icons.schedule,
        color: Colors.orange,
      ),
      _SummaryCard(
        title: 'Jobs',
        value: '${data['completedJobs']}',
        subtitle: '${data['activeJobs']} active',
        icon: Icons.work,
        color: Colors.purple,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildPayoutTile(BuildContext context, Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final completedDate = booking['completed_date'] != null
        ? DateTime.parse(booking['completed_date'] as String)
        : DateTime.parse(booking['scheduled_date'] as String);
    final dateLabel = DateFormat('MMM d, h:mm a').format(completedDate);
    final amount = ((booking['shop_payout'] ?? booking['final_price'] ?? booking['estimated_price']) as num?)
            ?.toDouble() ??
        0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.15),
          child: const Icon(Icons.attach_money, color: Colors.green),
        ),
        title: Text(_currency.format(amount)),
        subtitle: Text(dateLabel),
        trailing: Chip(
          label: Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[700])),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
