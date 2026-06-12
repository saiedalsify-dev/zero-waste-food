import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../core/config/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/donation.dart';
import '../models/notification_item.dart';

class TestAccount {
  const TestAccount({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final UserRole role;

  String get label => role.label;
}

class TestSeedResult {
  const TestSeedResult({required this.accounts, required this.donationCount});

  final List<TestAccount> accounts;
  final int donationCount;
}

abstract class TestSeedService {
  List<TestAccount> get accounts;
  Future<TestSeedResult> seed();
}

class FirebaseTestSeedService implements TestSeedService {
  FirebaseTestSeedService(this._auth, this._firestore);

  static const Duration _timeout = Duration(seconds: 20);
  static const String _testName = 'Saied Alsify';
  static const String _city = 'Cairo';

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  List<TestAccount> get accounts => const <TestAccount>[
    TestAccount(
      email: 'saied.alsify.donor@gmail.com',
      password: 'password123',
      role: UserRole.donor,
    ),
    TestAccount(
      email: 'saied.alsify.charity@gmail.com',
      password: 'password123',
      role: UserRole.charity,
    ),
    TestAccount(
      email: 'saied.alsify.admin@gmail.com',
      password: 'password123',
      role: UserRole.admin,
    ),
  ];

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirebaseCollections.users);

  CollectionReference<Map<String, dynamic>> get _donations =>
      _firestore.collection(FirebaseCollections.donations);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirebaseCollections.notifications);

  @override
  Future<TestSeedResult> seed() async {
    try {
      final seededUsers = <UserRole, AppUser>{};
      for (final account in accounts) {
        seededUsers[account.role] = await _ensureAccount(account);
      }

      final donor = seededUsers[UserRole.donor]!;
      final charity = seededUsers[UserRole.charity]!;
      final admin = seededUsers[UserRole.admin]!;

      await _auth
          .signInWithEmailAndPassword(
            email: accounts.first.email,
            password: accounts.first.password,
          )
          .timeout(_timeout);

      final donations = _buildDonations(donor: donor, charity: charity);
      for (final donation in donations) {
        await _donations
            .doc(donation.id)
            .set(donation.toMap(), SetOptions(merge: true))
            .timeout(_timeout);
      }

      await _writeTestNotifications(
        donor: donor,
        charity: charity,
        admin: admin,
        donations: donations,
      );
      await _writePendingBackfillNotifications(charity: charity, admin: admin);

      await _auth.signOut().timeout(_timeout);
      return TestSeedResult(
        accounts: accounts,
        donationCount: donations.length,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AppException(error.message ?? 'Unable to seed Firebase test data.');
    } catch (_) {
      throw const AppException(
        'Unable to create test data. Check Firebase Auth and Firestore rules.',
      );
    }
  }

  Future<AppUser> _ensureAccount(TestAccount account) async {
    firebase_auth.UserCredential credential;
    try {
      credential = await _auth
          .createUserWithEmailAndPassword(
            email: account.email,
            password: account.password,
          )
          .timeout(_timeout);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        rethrow;
      }
      credential = await _auth
          .signInWithEmailAndPassword(
            email: account.email,
            password: account.password,
          )
          .timeout(_timeout);
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const AppException('Unable to create Firebase test account.');
    }

    await firebaseUser.updateDisplayName(_testName).timeout(_timeout);

    final appUser = AppUser(
      id: firebaseUser.uid,
      name: _testName,
      email: account.email,
      role: account.role,
      city: _city,
      phone: '+20 100 000 0000',
      createdAt: DateTime.now(),
    );
    await _users
        .doc(appUser.id)
        .set(appUser.toMap(), SetOptions(merge: true))
        .timeout(_timeout);
    return appUser;
  }

  List<Donation> _buildDonations({
    required AppUser donor,
    required AppUser charity,
  }) {
    final now = DateTime.now();
    return <Donation>[
      Donation(
        id: 'test-pending-bread',
        donorId: donor.id,
        donorName: donor.name,
        title: 'Test pending bread packs',
        description: 'Seeded pending donation for Firebase testing.',
        quantity: 35,
        unit: 'Meals',
        expiryDate: now.add(const Duration(hours: 8)),
        city: _city,
        latitude: 30.0444,
        longitude: 31.2357,
        status: DonationStatus.pending,
        notes: 'Generated from test seed.',
        createdAt: now,
        updatedAt: now,
      ),
      Donation(
        id: 'test-pending-hotel-meals',
        donorId: donor.id,
        donorName: donor.name,
        title: 'Test pending hotel meals',
        description: 'Second seeded pending donation for list testing.',
        quantity: 70,
        unit: 'Meals',
        expiryDate: now.add(const Duration(hours: 18)),
        city: _city,
        latitude: 30.0444,
        longitude: 31.2357,
        status: DonationStatus.pending,
        notes: 'Generated from test seed.',
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now,
      ),
      Donation(
        id: 'test-accepted-vegetables',
        donorId: donor.id,
        donorName: donor.name,
        title: 'Test accepted vegetables',
        description: 'Seeded accepted donation for status testing.',
        quantity: 45,
        unit: 'Kg',
        expiryDate: now.add(const Duration(days: 2)),
        city: _city,
        status: DonationStatus.accepted,
        acceptedByCharityId: charity.id,
        acceptedByCharityName: charity.name,
        notes: 'Generated from test seed.',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      ),
      Donation(
        id: 'test-rejected-rice-boxes',
        donorId: donor.id,
        donorName: donor.name,
        title: 'Test rejected rice boxes',
        description: 'Seeded rejected donation for status testing.',
        quantity: 20,
        unit: 'Boxes',
        expiryDate: now.add(const Duration(days: 1)),
        city: _city,
        status: DonationStatus.rejected,
        notes: 'Generated from test seed.',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now,
      ),
    ];
  }

  Future<void> _writeTestNotifications({
    required AppUser donor,
    required AppUser charity,
    required AppUser admin,
    required List<Donation> donations,
  }) async {
    final now = DateTime.now();
    final pendingDonations = donations
        .where((donation) => donation.status == DonationStatus.pending)
        .toList();
    for (final donation in pendingDonations) {
      for (final recipient in <AppUser>[charity, admin]) {
        await _notifications
            .doc('test-${recipient.role.name}-${donation.id}')
            .set(
              NotificationItem(
                id: 'test-${recipient.role.name}-${donation.id}',
                userId: recipient.id,
                title: 'New donation available',
                body:
                    '${donation.title} in ${donation.city} - ${donation.quantity} ${donation.unit}',
                type: NotificationType.newDonation,
                relatedDonationId: donation.id,
                createdAt: now,
              ).toMap(),
              SetOptions(merge: true),
            )
            .timeout(_timeout);
      }
    }

    final acceptedDonation = donations.firstWhere(
      (donation) => donation.status == DonationStatus.accepted,
    );
    await _notifications
        .doc('test-donor-${acceptedDonation.id}')
        .set(
          NotificationItem(
            id: 'test-donor-${acceptedDonation.id}',
            userId: donor.id,
            title: 'Donation accepted',
            body: '${acceptedDonation.title} is now accepted.',
            type: NotificationType.donationAccepted,
            relatedDonationId: acceptedDonation.id,
            createdAt: now,
          ).toMap(),
          SetOptions(merge: true),
        )
        .timeout(_timeout);
  }

  Future<void> _writePendingBackfillNotifications({
    required AppUser charity,
    required AppUser admin,
  }) async {
    final snapshot = await _donations.get().timeout(_timeout);
    final existingPendingDonations = snapshot.docs
        .where((doc) => !doc.id.startsWith('test-'))
        .map((doc) => Donation.fromMap(doc.id, doc.data()))
        .where((donation) => donation.status == DonationStatus.pending)
        .toList();

    final now = DateTime.now();
    for (final donation in existingPendingDonations) {
      for (final recipient in <AppUser>[charity, admin]) {
        await _notifications
            .doc('backfill-${recipient.role.name}-${donation.id}')
            .set(
              NotificationItem(
                id: 'backfill-${recipient.role.name}-${donation.id}',
                userId: recipient.id,
                title: 'Pending donation waiting',
                body:
                    '${donation.title} in ${donation.city} - ${donation.quantity} ${donation.unit}',
                type: NotificationType.newDonation,
                relatedDonationId: donation.id,
                createdAt: now,
              ).toMap(),
              SetOptions(merge: true),
            )
            .timeout(_timeout);
      }
    }
  }
}

class DemoTestSeedService implements TestSeedService {
  @override
  List<TestAccount> get accounts => const <TestAccount>[
    TestAccount(
      email: 'donor@zerowaste.test',
      password: 'password123',
      role: UserRole.donor,
    ),
    TestAccount(
      email: 'charity@zerowaste.test',
      password: 'password123',
      role: UserRole.charity,
    ),
    TestAccount(
      email: 'admin@zerowaste.test',
      password: 'password123',
      role: UserRole.admin,
    ),
  ];

  @override
  Future<TestSeedResult> seed() async {
    return TestSeedResult(accounts: accounts, donationCount: 3);
  }
}
