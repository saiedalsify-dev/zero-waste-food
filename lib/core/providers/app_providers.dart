import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/donation.dart';
import '../../models/notification_item.dart';
import '../../services/auth_service.dart';
import '../../services/chatbot_service.dart';
import '../../services/donation_service.dart';
import '../../services/matching_service.dart';
import '../../services/notification_service.dart';
import '../services/firebase_bootstrap.dart';

final startupResultProvider = Provider<AppStartupResult>(
  (ref) => const AppStartupResult(mode: FirebaseMode.demo),
);

final authServiceProvider = Provider<AuthService>((ref) {
  final startup = ref.watch(startupResultProvider);
  if (startup.usesFirebase) {
    return FirebaseAuthService(
      firebase_auth.FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );
  }

  final service = DemoAuthService();
  ref.onDispose(service.dispose);
  return service;
});

final donationServiceProvider = Provider<DonationService>((ref) {
  final startup = ref.watch(startupResultProvider);
  if (startup.usesFirebase) {
    return FirestoreDonationService(FirebaseFirestore.instance);
  }

  final service = DemoDonationService();
  ref.onDispose(service.dispose);
  return service;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final startup = ref.watch(startupResultProvider);
  if (startup.usesFirebase) {
    return FirebaseNotificationService(
      FirebaseMessaging.instance,
      FirebaseFirestore.instance,
    );
  }

  final service = DemoNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final matchingServiceProvider = Provider<MatchingService>(
  (ref) => const MatchingService(),
);
final chatbotServiceProvider = Provider<ChatbotService>(
  (ref) => ChatbotService(),
);


final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final allDonationsProvider = StreamProvider<List<Donation>>((ref) {
  return ref.watch(donationServiceProvider).watchDonations();
});

final userDonationsProvider = StreamProvider.family<List<Donation>, String>((
  ref,
  userId,
) {
  return ref.watch(donationServiceProvider).watchDonationsForUser(userId);
});

final donationDetailsProvider = StreamProvider.family<Donation?, String>((
  ref,
  donationId,
) {
  return ref.watch(donationServiceProvider).watchDonation(donationId);
});

final userNotificationsProvider =
    StreamProvider.family<List<NotificationItem>, String>((ref, userId) {
      return ref.watch(notificationServiceProvider).watchNotifications(userId);
    });

final usersProvider = FutureProvider<List<AppUser>>((ref) {
  return ref.watch(authServiceProvider).fetchUsers();
});
