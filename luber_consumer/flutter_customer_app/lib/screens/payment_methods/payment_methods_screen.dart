import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/payment_method_model.dart';
import '../../providers/payment_method_provider.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaymentMethodProvider>().fetchPaymentMethods());
  }

  Future<void> _openAddScreen() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddPaymentMethodScreen(),
        fullscreenDialog: true,
      ),
    );
    if (added == true && mounted) {
      await context.read<PaymentMethodProvider>().fetchPaymentMethods();
    }
  }

  Future<void> _confirmDelete(PaymentMethodModel method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove payment method'),
        content: Text('Remove ${method.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<PaymentMethodProvider>().deletePaymentMethod(method.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Card removed' : 'Unable to remove card'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _setDefault(PaymentMethodModel method) async {
    final success = await context.read<PaymentMethodProvider>().setDefault(method.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Default payment updated' : 'Failed to update payment method'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentMethodProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: const Color(0xFF0070F3),
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _PaymentError(
                  message: provider.error!,
                  onRetry: () => provider.fetchPaymentMethods(),
                )
              : provider.paymentMethods.isEmpty
                  ? _PaymentEmpty(onAdd: _openAddScreen)
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchPaymentMethods(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.paymentMethods.length,
                        itemBuilder: (context, index) {
                          final method = provider.paymentMethods[index];
                          return _PaymentMethodTile(
                            method: method,
                            onDelete: () => _confirmDelete(method),
                            onSetDefault: () => _setDefault(method),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
        backgroundColor: const Color(0xFF0070F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
    );
  }
}

class _PaymentEmpty extends StatelessWidget {
  final VoidCallback onAdd;

  const _PaymentEmpty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No cards on file',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a payment method to complete bookings faster.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PaymentError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Unable to load payment methods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _PaymentMethodTile({
    required this.method,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0070F3).withOpacity(0.1),
          child: const Icon(Icons.credit_card, color: Color(0xFF0070F3)),
        ),
        title: Text(
          method.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          method.isDefault ? 'Default payment method' : 'Added on ${method.createdAt.toLocal().toString().split(' ').first}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'default':
                onSetDefault();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!method.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as default'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
