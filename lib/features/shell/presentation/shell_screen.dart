import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_manager.dart';

const double largeScreenMinWidth = 600.0;

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > largeScreenMinWidth) {
          return _buildLargeScreenLayout(context, ref);
        } else {
          return _buildSmallScreenLayout(context, ref);
        }
      },
    );
  }

  Widget _buildSyncStatus(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncManagerProvider);
    IconData icon;
    Color color;
    String text;
    switch (status) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        text = 'Syncing...';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = Colors.grey;
        text = 'Offline';
        break;
      case SyncStatus.error:
        icon = Icons.sync_problem;
        color = Colors.red;
        text = 'Failed';
        break;
      case SyncStatus.pending:
        icon = Icons.pending;
        color = Colors.orange;
        text = 'Pending';
        break;
      case SyncStatus.idle:
      default:
        icon = Icons.cloud_done;
        color = Colors.green;
        text = 'Synced';
        break;
    }
    return Tooltip(
      message: text,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: () =>
            ref.read(syncManagerProvider.notifier).triggerManualSync(),
      ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing App'),
        actions: [
          _buildSyncStatus(context, ref),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart),
                label: Text('Sales'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag),
                label: Text('Purchases'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart),
                label: Text('Reports'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing App'),
        actions: [
          _buildSyncStatus(context, ref),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _showProfileBottomSheet(context),
          ),
        ],
      ),
      drawer: _buildMobileDrawer(context, ref),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Purchases',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Store Admin'),
              accountEmail: const Text('admin@billing.app'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Icon(Icons.store,
                    color: Theme.of(context).colorScheme.primary),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Data'),
              onTap: () {
                Navigator.pop(context);
                ref.read(syncManagerProvider.notifier).triggerManualSync();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                  radius: 32, child: Icon(Icons.person, size: 32)),
              const SizedBox(height: 16),
              Text('Store Admin',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('admin@billing.app',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.receipt_long,
                      label: 'New Sale',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/sales');
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.add_box,
                      label: 'Add Item',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/inventory');
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.person_add,
                      label: 'Customer',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/sales')) return 1;
    if (location.startsWith('/purchases')) return 2;
    if (location.startsWith('/inventory')) return 3;
    if (location.startsWith('/reports')) return 4;
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/sales');
        break;
      case 2:
        context.go('/purchases/new');
        break;
      case 3:
        context.go('/inventory');
        break;
      case 4:
        context.go('/reports');
        break;
    }
  }
}
