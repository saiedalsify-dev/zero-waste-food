import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/notification_item.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final startup = ref.watch(startupResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (_, __) => const _NoUserNotifications(),
        data: (user) {
          if (user == null) {
            return const _NoUserNotifications();
          }
          final notificationsAsync = ref.watch(
            userNotificationsProvider(user.id),
          );
          return notificationsAsync.when(
            loading: () =>
                const LoadingView(message: 'Loading notifications...'),
            error: (_, __) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load notifications',
              message: 'Check Firebase permissions and try again.',
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications',
                  message: startup.mode == FirebaseMode.demo
                      ? 'Demo notifications appear after adding or accepting donations.'
                      : 'Firebase Cloud Messaging is ready after permissions are granted.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationCard(item: item);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: item.read
          ? colorScheme.surface
          : colorScheme.primaryContainer.withAlpha(120),
      child: ListTile(
        leading: Icon(_iconForType(item.type), color: colorScheme.primary),
        title: Text(item.title),
        subtitle: Text(
          '${item.body}\n${DateFormatters.dateTime(item.createdAt)}',
        ),
        isThreeLine: true,
        trailing: item.read
            ? null
            : const Icon(Icons.mark_email_unread_outlined),
        onTap: () async {
          await ref.read(notificationServiceProvider).markAsRead(item.id);
          if (item.relatedDonationId != null && context.mounted) {
            Navigator.of(context).pushNamed(
              AppRoutes.donationDetails,
              arguments: item.relatedDonationId,
            );
          }
        },
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newDonation:
        return Icons.add_alert_outlined;
      case NotificationType.donationAccepted:
        return Icons.check_circle_outline;
      case NotificationType.statusUpdate:
        return Icons.update_outlined;
    }
  }
}

class _NoUserNotifications extends StatelessWidget {
  const _NoUserNotifications();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_outline,
      title: 'Sign in required',
      message: 'Please sign in to view notifications.',
    );
  }
}
