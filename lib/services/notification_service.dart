import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/config/app_constants.dart';
import '../core/config/firebase_options.dart';
import '../core/errors/app_exception.dart';
import '../models/donation.dart';
import '../models/notification_item.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (DefaultFirebaseOptions.isConfigured && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

abstract class NotificationService {
  Future<void> initializeForUser(String userId);
  Stream<List<NotificationItem>> watchNotifications(String userId);
  Future<void> createNotification(NotificationItem notification);
  Future<void> markAsRead(String notificationId);
  Future<void> notifyNewDonation(Donation donation);
  Future<void> notifyDonationStatus({
    required Donation donation,
    required String recipientUserId,
    required NotificationType type,
  });
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService(this._messaging, this._firestore);

  static const Duration _setupTimeout = Duration(seconds: 5);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirebaseCollections.notifications);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirebaseCollections.users);

  @override
  Future<void> initializeForUser(String userId) async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _messaging.requestPermission().timeout(_setupTimeout);
      final token = await _messaging.getToken().timeout(_setupTimeout);
      if (token != null) {
        await _users
            .doc(userId)
            .set(<String, Object?>{'fcmToken': token}, SetOptions(merge: true))
            .timeout(_setupTimeout);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _users.doc(userId).set(<String, Object?>{
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (_) {
      throw const AppException('Unable to initialize notifications.');
    }
  }

  @override
  Stream<List<NotificationItem>> watchNotifications(String userId) async* {
    try {
      await for (final snapshot in _notifications.snapshots()) {
        final notifications = snapshot.docs
            .map((doc) => NotificationItem.fromMap(doc.id, doc.data()))
            .where((notification) => notification.userId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield notifications;
      }
    } on FirebaseException catch (error) {
      throw AppException(
        'Notification load failed: ${error.code}. ${error.message ?? ''}',
      );
    } catch (_) {
      throw const AppException('Unable to load notifications.');
    }
  }

  @override
  Future<void> createNotification(NotificationItem notification) async {
    try {
      final doc = notification.id.isEmpty
          ? _notifications.doc()
          : _notifications.doc(notification.id);
      await doc.set(notification.copyWith(id: doc.id).toMap());
    } catch (_) {
      throw const AppException('Unable to create notification.');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).set(<String, Object?>{
        'read': true,
      }, SetOptions(merge: true));
    } catch (_) {
      throw const AppException('Unable to update notification.');
    }
  }

  @override
  Future<void> notifyNewDonation(Donation donation) async {
    try {
      final recipients = await _users
          .where('role', whereIn: <String>['charity', 'admin'])
          .get();
      for (final recipient in recipients.docs) {
        await createNotification(
          NotificationItem(
            id: '',
            userId: recipient.id,
            title: 'New donation available',
            body:
                '${donation.title} in ${donation.city} - ${donation.quantity} ${donation.unit}',
            type: NotificationType.newDonation,
            relatedDonationId: donation.id,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      throw const AppException('Unable to notify charities.');
    }
  }

  @override
  Future<void> notifyDonationStatus({
    required Donation donation,
    required String recipientUserId,
    required NotificationType type,
  }) async {
    await createNotification(
      NotificationItem(
        id: '',
        userId: recipientUserId,
        title: type.label,
        body: '${donation.title} is now ${donation.status.label.toLowerCase()}.',
        type: type,
        relatedDonationId: donation.id,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class DemoNotificationService implements NotificationService {
  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();
  final List<NotificationItem> _notifications = <NotificationItem>[];

  @override
  Future<void> initializeForUser(String userId) async {}

  @override
  Stream<List<NotificationItem>> watchNotifications(String userId) async* {
    yield _forUser(userId);
    yield* _controller.stream.map((_) => _forUser(userId));
  }

  @override
  Future<void> createNotification(NotificationItem notification) async {
    final created = notification.copyWith(
      id: notification.id.isEmpty
          ? 'notification-${DateTime.now().microsecondsSinceEpoch}'
          : notification.id,
    );
    _notifications.add(created);
    _emit();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _emit();
    }
  }

  @override
  Future<void> notifyNewDonation(Donation donation) async {}

  @override
  Future<void> notifyDonationStatus({
    required Donation donation,
    required String recipientUserId,
    required NotificationType type,
  }) async {
    await createNotification(
      NotificationItem(
        id: '',
        userId: recipientUserId,
        title: type.label,
        body: '${donation.title} is now ${donation.status.label.toLowerCase()}.',
        type: type,
        relatedDonationId: donation.id,
        createdAt: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _controller.close();
  }

  List<NotificationItem> _forUser(String userId) {
    return _notifications.where((item) => item.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _emit() {
    _controller.add(List<NotificationItem>.unmodifiable(_notifications));
  }
}