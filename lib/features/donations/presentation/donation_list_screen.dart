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

class DonationListScreen extends ConsumerStatefulWidget {
  const DonationListScreen({super.key});

  @override
  ConsumerState<DonationListScreen> createState() => _DonationListScreenState();
}

class _DonationListScreenState extends ConsumerState<DonationListScreen> {
  final _cityController = TextEditingController();
  DonationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _cityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Donations')),
      floatingActionButton: authState.maybeWhen(
        data: (user) => user != null && user.isDonor
            ? FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.addDonation),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              )
            : null,
        orElse: () => null,
      ),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load session',
          message: 'Please sign in again.',
        ),
        data: (user) {
          if (user == null) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Sign in required',
              message: 'Please sign in to view donations.',
            );
          }
          return _DonationListContent(
            user: user,
            cityFilter: _effectiveCityFilter(user),
            selectedStatus: user.isCharity
                ? DonationStatus.pending
                : _selectedStatus,
            cityController: _cityController,
            onStatusChanged: (status) =>
                setState(() => _selectedStatus = status),
          );
        },
      ),
    );
  }

  String? _effectiveCityFilter(AppUser user) {
    final typedCity = _cityController.text.trim();
    if (typedCity.isNotEmpty) {
      return typedCity;
    }
    return user.isCharity ? user.city : null;
  }
}

class _DonationListContent extends ConsumerWidget {
  const _DonationListContent({
    required this.user,
    required this.cityFilter,
    required this.selectedStatus,
    required this.cityController,
    required this.onStatusChanged,
  });

  final AppUser user;
  final String? cityFilter;
  final DonationStatus? selectedStatus;
  final TextEditingController cityController;
  final ValueChanged<DonationStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationService = ref.watch(donationServiceProvider);
    final stream = user.isDonor
        ? donationService.watchDonationsForUser(user.id)
        : donationService.watchDonations(
            city: cityFilter,
            status: selectedStatus,
          );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: user.isCharity
                      ? 'Nearby city filter (${user.city})'
                      : 'City filter',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  suffixIcon: cityController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: cityController.clear,
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              if (!user.isCharity && !user.isDonor) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<DonationStatus?>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.tune_outlined),
                  ),
                  items: <DropdownMenuItem<DonationStatus?>>[
                    const DropdownMenuItem<DonationStatus?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...DonationStatus.values.map(
                      (status) => DropdownMenuItem<DonationStatus?>(
                        value: status,
                        child: Text(status.label),
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Donation>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LoadingView(message: 'Loading donations...');
              }
              if (snapshot.hasError) {
                return const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load donations',
                  message: 'Check Firebase permissions and try again.',
                );
              }

              final donations = snapshot.data ?? <Donation>[];
              if (donations.isEmpty) {
                return const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No donations found',
                  message: 'Adjust filters or add a new donation.',
                );
              }

              final matchingService = ref.watch(matchingServiceProvider);
              final scoreById = <String, int>{};
              final visibleDonations = user.isCharity
                  ? matchingService.rankDonations(donations).map((result) {
                      scoreById[result.donation.id] = result.score;
                      return result.donation;
                    }).toList()
                  : donations;

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: visibleDonations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final donation = visibleDonations[index];
                  return _DonationCard(
                    donation: donation,
                    score: scoreById[donation.id],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.donation, this.score});

  final Donation donation;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.donationDetails, arguments: donation),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      donation.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusChip(status: donation.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                donation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  _IconText(
                    icon: Icons.scale_outlined,
                    text: '${donation.quantity} ${donation.unit}',
                  ),
                  _IconText(
                    icon: Icons.location_city_outlined,
                    text: donation.city,
                  ),
                  _IconText(
                    icon: Icons.schedule_outlined,
                    text: DateFormatters.relativeExpiry(donation.expiryDate),
                  ),
                  if (score != null)
                    _IconText(
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

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
