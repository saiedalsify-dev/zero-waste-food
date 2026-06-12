import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/text_info_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final startup = ref.watch(startupResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (_, __) => const _NoProfile(),
        data: (user) {
          if (user == null) {
            return const _NoProfile();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 34,
                        child: Text(
                          user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(user.role.label),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      TextInfoRow(
                        label: 'Email',
                        value: user.email,
                        icon: Icons.email_outlined,
                      ),
                      TextInfoRow(
                        label: 'City',
                        value: user.city,
                        icon: Icons.location_city_outlined,
                      ),
                      TextInfoRow(
                        label: 'Phone',
                        value: user.phone ?? 'Not provided',
                        icon: Icons.phone_outlined,
                      ),
                      TextInfoRow(
                        label: 'Backend',
                        value: startup.mode == FirebaseMode.firebase
                            ? 'Firebase'
                            : 'Demo services',
                        icon: Icons.cloud_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoProfile extends StatelessWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.person_off_outlined,
      title: 'No profile',
      message: 'Please sign in to view your profile.',
    );
  }
}
