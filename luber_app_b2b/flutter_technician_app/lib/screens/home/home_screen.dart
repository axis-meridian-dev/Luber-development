import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = context.read<JobProvider>();
      jobProvider.fetchShopTechnician().then((_) {
        jobProvider.fetchAvailableJobs();
        jobProvider.fetchMyJobs();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<JobProvider>(
          builder: (context, jobProvider, child) {
            return Text(jobProvider.shop?['shop_name'] ?? 'Luber Pro');
          },
        ),
        actions: [
          Consumer<JobProvider>(
            builder: (context, jobProvider, child) {
              return Row(
                children: [
                  Text(
                    jobProvider.isAvailable ? 'Available' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: jobProvider.isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                  Switch(
                    value: jobProvider.isAvailable,
                    onChanged: (_) => jobProvider.toggleAvailability(),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildAvailableJobsTab() : _buildMyJobsTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Available',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'My Jobs',
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsTab() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        if (jobProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (jobProvider.shop != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Working for ${jobProvider.shop!['shop_name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${jobProvider.shopTechnician?['total_jobs'] ?? 0} jobs completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: jobProvider.availableJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No available jobs',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new bookings',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => jobProvider.fetchAvailableJobs(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: jobProvider.availableJobs.length,
                        itemBuilder: (context, index) {
                          final job = jobProvider.availableJobs[index];
                          return _buildAvailableJobCard(job, jobProvider);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableJobCard(
      Map<String, dynamic> job, JobProvider jobProvider) {
    final package = job['shop_service_packages'] as Map<String, dynamic>?;
    final packageName = package?['package_name'] ?? job['service_type'] ?? 'Oil Change';
    final price = package?['price'] ?? job['estimated_price'];
    final scheduledDate = DateTime.parse(job['scheduled_date']);
    final address = job['service_address'] as String;
    final city = job['service_city'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.build,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (price != null)
                  Text(
                    '\$$price',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$address, $city',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (package != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (package['oil_brand'] != null)
                    Chip(
                      label: Text(package['oil_brand'], style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.blue[50],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (package['oil_type'] != null)
                    Chip(
                      label: Text(package['oil_type'], style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.green[50],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/job/${job['id']}'),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final success = await jobProvider.acceptJob(job['id']);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job accepted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobsTab() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        if (jobProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (jobProvider.myJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active jobs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accept jobs to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => jobProvider.fetchMyJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobProvider.myJobs.length,
            itemBuilder: (context, index) {
              final job = jobProvider.myJobs[index];
              return _buildMyJobCard(job);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyJobCard(Map<String, dynamic> job) {
    final status = job['status'] as String;
    final package = job['shop_service_packages'] as Map<String, dynamic>?;
    final packageName = package?['package_name'] ?? job['service_type'] ?? 'Oil Change';
    final scheduledDate = DateTime.parse(job['scheduled_date']);

    Color statusColor;
    switch (status) {
      case 'accepted':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.build, color: statusColor),
        ),
        title: Text(packageName),
        subtitle: Text(
          '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
        ),
        trailing: Chip(
          label: Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
          side: BorderSide.none,
        ),
        onTap: () => context.push('/job/${job['id']}'),
      ),
    );
  }
}
