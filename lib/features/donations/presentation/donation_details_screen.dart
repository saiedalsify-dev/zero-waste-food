import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/text_info_row.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';
import '../../../models/notification_item.dart';

class DonationDetailsScreen extends ConsumerStatefulWidget {
  const DonationDetailsScreen({
    required this.donationId,
    this.initialDonation,
    super.key,
  });

  final String donationId;
  final Donation? initialDonation;

  @override
  ConsumerState<DonationDetailsScreen> createState() =>
      _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends ConsumerState<DonationDetailsScreen> {
  bool _isUpdating = false;

  Future<void> _changeStatus({
    required Donation donation,
    required AppUser user,
    required DonationStatus status,
  }) async {
    setState(() => _isUpdating = true);
    try {
      final charityId = status == DonationStatus.accepted
          ? user.id
          : donation.acceptedByCharityId;
      final charityName = status == DonationStatus.accepted
          ? user.name
          : donation.acceptedByCharityName;
      await ref
          .read(donationServiceProvider)
          .updateStatus(
            donationId: donation.id,
            status: status,
            charityId: charityId,
            charityName: charityName,
          );
      final updated = donation.copyWith(
        status: status,
        acceptedByCharityId: charityId,
        acceptedByCharityName: charityName,
      );
      await ref
          .read(notificationServiceProvider)
          .notifyDonationStatus(
            donation: updated,
            recipientUserId: donation.donorId,
            type: status == DonationStatus.accepted
                ? NotificationType.donationAccepted
                : NotificationType.statusUpdate,
          );
      _showMessage('Donation marked as ${status.label.toLowerCase()}.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to update donation.');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final donationAsync = ref.watch(donationDetailsProvider(widget.donationId));
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Donation details')),
      body: donationAsync.when(
        loading: () => widget.initialDonation == null
            ? const LoadingView(message: 'Loading donation...')
            : _buildDetails(widget.initialDonation!, authAsync),
        error: (_, __) => widget.initialDonation == null
            ? const EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load donation',
                message:
                    'The donation may have been removed or permissions are missing.',
              )
            : _buildDetails(widget.initialDonation!, authAsync),
        data: (donation) {
          final currentDonation = donation ?? widget.initialDonation;
          if (currentDonation == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Donation not found',
              message: 'Return to the donation list and try again.',
            );
          }

          return _buildDetails(currentDonation, authAsync);
        },
      ),
    );
  }

  Widget _buildDetails(Donation donation, AsyncValue<AppUser?> authAsync) {
    return authAsync.when(
      loading: () => const LoadingView(),
      error: (_, __) => _DetailsBody(donation: donation),
      data: (user) => _DetailsBody(
        donation: donation,
        user: user,
        isUpdating: _isUpdating,
        onStatusChange: user == null
            ? null
            : (status) =>
                  _changeStatus(donation: donation, user: user, status: status),
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({
    required this.donation,
    this.user,
    this.isUpdating = false,
    this.onStatusChange,
  });

  final Donation donation;
  final AppUser? user;
  final bool isUpdating;
  final ValueChanged<DonationStatus>? onStatusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingResult = ref
        .watch(matchingServiceProvider)
        .scoreDonation(donation);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                donation.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StatusChip(status: donation.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(donation.description),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                TextInfoRow(
                  label: 'Quantity',
                  value: '${donation.quantity} ${donation.unit}',
                  icon: Icons.scale_outlined,
                ),
                TextInfoRow(
                  label: 'Expiry',
                  value: DateFormatters.dateTime(donation.expiryDate),
                  icon: Icons.schedule_outlined,
                ),
                TextInfoRow(
                  label: 'Urgency',
                  value: DateFormatters.relativeExpiry(donation.expiryDate),
                  icon: Icons.timelapse_outlined,
                ),
                TextInfoRow(
                  label: 'City',
                  value: donation.city,
                  icon: Icons.location_city_outlined,
                ),
                TextInfoRow(
                  label: 'Coordinates',
                  value: donation.hasCoordinates
                      ? '${donation.latitude}, ${donation.longitude}'
                      : 'Not provided',
                  icon: Icons.my_location_outlined,
                ),
                TextInfoRow(
                  label: 'Donor',
                  value: donation.donorName,
                  icon: Icons.person_outline,
                ),
                if (donation.acceptedByCharityName != null)
                  TextInfoRow(
                    label: 'Charity',
                    value: donation.acceptedByCharityName!,
                    icon: Icons.diversity_1_outlined,
                  ),
                if (donation.notes != null && donation.notes!.isNotEmpty)
                  TextInfoRow(
                    label: 'Notes',
                    value: donation.notes!,
                    icon: Icons.info_outline,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.priority_high_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rule-based score: ${matchingResult.score}/100',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final reason in matchingResult.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- $reason'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (user != null)
          _ActionButtons(
            user: user!,
            donation: donation,
            isUpdating: isUpdating,
            onStatusChange: onStatusChange,
          ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.user,
    required this.donation,
    required this.isUpdating,
    required this.onStatusChange,
  });

  final AppUser user;
  final Donation donation;
  final bool isUpdating;
  final ValueChanged<DonationStatus>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    if (onStatusChange == null) {
      return const SizedBox.shrink();
    }

    if (user.isCharity && donation.status == DonationStatus.pending) {
      return Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: isUpdating
                  ? null
                  : () => onStatusChange!(DonationStatus.accepted),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isUpdating
                  ? null
                  : () => onStatusChange!(DonationStatus.rejected),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
            ),
          ),
        ],
      );
    }

    final canComplete =
        donation.status == DonationStatus.accepted &&
        (user.id == donation.donorId ||
            user.id == donation.acceptedByCharityId ||
            user.isAdmin);
    if (canComplete) {
      return FilledButton.icon(
        onPressed: isUpdating
            ? null
            : () => onStatusChange!(DonationStatus.completed),
        icon: const Icon(Icons.done_all_outlined),
        label: const Text('Mark completed'),
      );
    }

    return const SizedBox.shrink();
  }
}
