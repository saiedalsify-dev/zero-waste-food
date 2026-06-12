import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (_, __) => const _AdminOnly(),
        data: (user) {
          if (user == null || !user.isAdmin) {
            return const _AdminOnly();
          }
          return const _AdminContent();
        },
      ),
    );
  }
}

class _AdminContent extends ConsumerWidget {
  const _AdminContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final donationsAsync = ref.watch(allDonationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(usersProvider);
        ref.invalidate(allDonationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          donationsAsync.when(
            loading: () =>
                const LoadingView(message: 'Loading donation summary...'),
            error: (_, __) => const SizedBox.shrink(),
            data: (donations) => _DonationSummary(donations: donations),
          ),
          const SizedBox(height: 16),
          Text('Users', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          usersAsync.when(
            loading: () => const LoadingView(message: 'Loading users...'),
            error: (_, __) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load users',
              message: 'Check Firebase permissions and try again.',
            ),
            data: (users) => Column(
              children: users.map((user) => _UserCard(user: user)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationSummary extends StatelessWidget {
  const _DonationSummary({required this.donations});

  final List<Donation> donations;

  @override
  Widget build(BuildContext context) {
    final pending = donations
        .where((donation) => donation.status == DonationStatus.pending)
        .length;
    final accepted = donations
        .where((donation) => donation.status == DonationStatus.accepted)
        .length;
    final completed = donations
        .where((donation) => donation.status == DonationStatus.completed)
        .length;

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: <Widget>[
        _SummaryCard(
          label: 'All donations',
          value: donations.length.toString(),
          icon: Icons.inventory_2_outlined,
        ),
        _SummaryCard(
          label: 'Pending',
          value: pending.toString(),
          icon: Icons.pending_actions_outlined,
        ),
        _SummaryCard(
          label: 'Accepted',
          value: accepted.toString(),
          icon: Icons.task_alt,
        ),
        _SummaryCard(
          label: 'Completed',
          value: completed.toString(),
          icon: Icons.done_all_outlined,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(user.name),
          subtitle: Text('${user.email}\n${user.role.label} - ${user.city}'),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _AdminOnly extends StatelessWidget {
  const _AdminOnly();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Admin access only',
      message: 'This screen is available to admin accounts.',
    );
  }
}
