import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: LoadingView(message: 'Opening dashboard...')),
      error: (_, __) => const _SignedOutView(),
      data: (user) {
        if (user == null) {
          return const _SignedOutView();
        }
        return _Dashboard(user: user);
      },
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(allDonationsProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _initialFor(user.name),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _AppDrawer(user: user),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allDonationsProvider);
            ref.invalidate(userNotificationsProvider(user.id));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _WelcomeHeader(user: user),
              const SizedBox(height: 24),
              donationsAsync.when(
                loading: () =>
                    const LoadingView(message: 'Loading donation summary...'),
                error: (_, __) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load donations',
                  message: 'Check Firebase setup or try again.',
                ),
                data: (donations) {
                  final unread = notificationsAsync.maybeWhen(
                    data: (items) => items.where((item) => !item.read).length,
                    orElse: () => 0,
                  );
                  return _MetricGrid(
                    donations: donations,
                    user: user,
                    unreadNotifications: unread,
                  );
                },
              ),
              if (user.isDonor) ...<Widget>[
                const SizedBox(height: 18),
                const _PrimaryDonationCta(),
              ],
              const SizedBox(height: 24),
              _ActionGrid(user: user),
              const SizedBox(height: 28),
              if (user.isCharity)
                _CharityPriorityList(user: user)
              else if (user.isDonor)
                _DonorRecentList(user: user)
              else
                _AdminQuickSummary(user: user),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.onPrimary,
            child: Text(
              _initialFor(user.name),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome, ${user.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.role.label} - ${user.city}',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withAlpha(220),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _contextMessage(user),
                  style: TextStyle(color: colorScheme.onPrimary.withAlpha(226)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _contextMessage(AppUser user) {
    if (user.isDonor) {
      return 'Ready to share surplus food today.';
    }
    if (user.isCharity) {
      return 'Prioritize urgent pickups around ${user.city}.';
    }
    return 'Monitor users, donations, and status updates.';
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.donations,
    required this.user,
    required this.unreadNotifications,
  });

  final List<Donation> donations;
  final AppUser user;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final visibleDonations = user.isDonor
        ? donations.where((donation) => donation.donorId == user.id).toList()
        : donations;
    final pending = visibleDonations
        .where((donation) => donation.status == DonationStatus.pending)
        .length;
    final accepted = visibleDonations
        .where((donation) => donation.status == DonationStatus.accepted)
        .length;

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.45,
      children: <Widget>[
        _MetricCard(
          label: 'Total Donations',
          value: visibleDonations.length.toString(),
          icon: Icons.inventory_2_outlined,
          background: const Color(0xFFE3F0FF),
          foreground: const Color(0xFF105C9F),
        ),
        _MetricCard(
          label: 'Pending',
          value: pending.toString(),
          icon: Icons.pending_actions_outlined,
          background: const Color(0xFFFFF1C7),
          foreground: const Color(0xFF8A5A00),
        ),
        _MetricCard(
          label: 'Accepted',
          value: accepted.toString(),
          icon: Icons.task_alt,
          background: const Color(0xFFDDF8E6),
          foreground: const Color(0xFF126336),
        ),
        _MetricCard(
          label: 'Unread',
          value: unreadNotifications.toString(),
          icon: Icons.notifications_active_outlined,
          background: const Color(0xFFFFE2E2),
          foreground: const Color(0xFF9A2A2A),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(210),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: foreground, size: 20),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryDonationCta extends StatelessWidget {
  const _PrimaryDonationCta();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: const Color(0xFF0F6B4A),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addDonation),
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Add New Donation'),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final actions = <_DashboardAction>[
      const _DashboardAction(
        'Donations',
        Icons.list_alt_outlined,
        AppRoutes.donations,
      ),
      const _DashboardAction(
        'Chatbot',
        Icons.chat_bubble_outline,
        AppRoutes.chatbot,
      ),
      const _DashboardAction('Open Map', Icons.map_outlined, AppRoutes.map),
      const _DashboardAction(
        'Profile',
        Icons.person_outline,
        AppRoutes.profile,
      ),
      if (user.isAdmin)
        const _DashboardAction(
          'Admin',
          Icons.admin_panel_settings_outlined,
          AppRoutes.admin,
        ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.25,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).pushNamed(action.route),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Icon(
                    action.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CharityPriorityList extends ConsumerWidget {
  const _CharityPriorityList({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(allDonationsProvider);
    final matchingService = ref.watch(matchingServiceProvider);

    return donationsAsync.when(
      loading: () => const LoadingView(message: 'Ranking nearby donations...'),
      error: (_, __) => const SizedBox.shrink(),
      data: (donations) {
        final nearby = donations
            .where(
              (donation) =>
                  donation.city.toLowerCase().contains(user.city.toLowerCase()),
            )
            .toList();
        final ranked = matchingService.rankDonations(nearby).take(3).toList();
        if (ranked.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No nearby pending donations',
            message: 'Try the donation list to broaden the city filter.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _SectionTitle(
              icon: Icons.priority_high_outlined,
              title: 'Highest priority nearby',
            ),
            const SizedBox(height: 14),
            for (final result in ranked) ...<Widget>[
              _DonationPreview(donation: result.donation, score: result.score),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _DonorRecentList extends ConsumerWidget {
  const _DonorRecentList({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(userDonationsProvider(user.id));

    return donationsAsync.when(
      loading: () => const LoadingView(message: 'Loading your donations...'),
      error: (_, __) => const SizedBox.shrink(),
      data: (donations) {
        if (donations.isEmpty) {
          return const EmptyState(
            icon: Icons.add_box_outlined,
            title: 'No donations yet',
            message: 'Add your first donation when surplus food is available.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _SectionTitle(
              icon: Icons.history_outlined,
              title: 'Recent donations',
            ),
            const SizedBox(height: 14),
            for (final donation in donations.take(3)) ...<Widget>[
              _DonationPreview(donation: donation),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AdminQuickSummary extends StatelessWidget {
  const _AdminQuickSummary({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: const Text('Admin overview'),
        subtitle: const Text(
          'Review users and donations from the admin screen.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.admin),
      ),
    );
  }
}

class _DonationPreview extends StatelessWidget {
  const _DonationPreview({required this.donation, this.score});

  final Donation donation;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.donationDetails, arguments: donation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      score == null
                          ? donation.quantity.round().toString()
                          : score.toString(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          donation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${donation.quantity} ${donation.unit} from ${donation.donorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: donation.status),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: <Widget>[
                  _PreviewMeta(
                    icon: Icons.location_city_outlined,
                    text: donation.city,
                  ),
                  _PreviewMeta(
                    icon: Icons.schedule_outlined,
                    text: DateFormatters.relativeExpiry(donation.expiryDate),
                  ),
                  if (score != null)
                    _PreviewMeta(
                      icon: Icons.priority_high_outlined,
                      text: 'Score $score',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMeta extends StatelessWidget {
  const _PreviewMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Text(user.name),
              subtitle: Text(user.role.label),
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            ),
            const Divider(),
            _DrawerItem(
              label: 'Home',
              icon: Icons.home_outlined,
              route: AppRoutes.home,
            ),
            if (user.isDonor)
              _DrawerItem(
                label: 'Add Donation',
                icon: Icons.add_circle_outline,
                route: AppRoutes.addDonation,
              ),
            _DrawerItem(
              label: 'Donations',
              icon: Icons.list_alt_outlined,
              route: AppRoutes.donations,
            ),
            _DrawerItem(
              label: 'Notifications',
              icon: Icons.notifications_outlined,
              route: AppRoutes.notifications,
            ),
            _DrawerItem(
              label: 'Chatbot',
              icon: Icons.chat_bubble_outline,
              route: AppRoutes.chatbot,
            ),
            _DrawerItem(
              label: 'Profile',
              icon: Icons.person_outline,
              route: AppRoutes.profile,
            ),
            if (user.isAdmin)
              _DrawerItem(
                label: 'Admin',
                icon: Icons.admin_panel_settings_outlined,
                route: AppRoutes.admin,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      },
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.lock_outline,
        title: 'Session ended',
        message: 'Please sign in again to continue.',
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          icon: const Icon(Icons.login),
          label: const Text('Go to login'),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}
