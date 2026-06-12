import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/config/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/donation.dart';

abstract class DonationService {
  Stream<List<Donation>> watchDonations({String? city, DonationStatus? status});
  Stream<List<Donation>> watchDonationsForUser(String userId);
  Stream<Donation?> watchDonation(String donationId);
  Future<Donation> createDonation(Donation donation);
  Future<void> updateDonation(Donation donation);
  Future<void> updateStatus({
    required String donationId,
    required DonationStatus status,
    String? charityId,
    String? charityName,
  });
  Future<void> deleteDonation(String donationId);
}

class FirestoreDonationService implements DonationService {
  FirestoreDonationService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _donations =>
      _firestore.collection(FirebaseCollections.donations);

  @override
  Stream<List<Donation>> watchDonations({
    String? city,
    DonationStatus? status,
  }) async* {
    try {
      await for (final snapshot in _donations.snapshots()) {
        final donations = snapshot.docs
            .map((doc) => Donation.fromMap(doc.id, doc.data()))
            .where(
              (donation) =>
                  _matchesFilters(donation, city: city, status: status),
            )
            .toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        yield donations;
      }
    } on FirebaseException catch (error) {
      throw AppException(
        'Donation load failed: ${error.code}. ${error.message ?? ''}',
      );
    } catch (_) {
      throw const AppException('Unable to load donations.');
    }
  }

  @override
  Stream<List<Donation>> watchDonationsForUser(String userId) async* {
    try {
      await for (final snapshot in _donations.snapshots()) {
        final donations = snapshot.docs
            .map((doc) => Donation.fromMap(doc.id, doc.data()))
            .where((donation) => donation.donorId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield donations;
      }
    } on FirebaseException catch (error) {
      throw AppException(
        'Donation load failed: ${error.code}. ${error.message ?? ''}',
      );
    } catch (_) {
      throw const AppException('Unable to load donations.');
    }
  }

  @override
  Stream<Donation?> watchDonation(String donationId) async* {
    try {
      await for (final snapshot in _donations.doc(donationId).snapshots()) {
        if (!snapshot.exists || snapshot.data() == null) {
          yield null;
        } else {
          yield Donation.fromMap(snapshot.id, snapshot.data()!);
        }
      }
    } on FirebaseException catch (error) {
      throw AppException(
        'Donation load failed: ${error.code}. ${error.message ?? ''}',
      );
    } catch (_) {
      throw const AppException('Unable to load donation.');
    }
  }

  @override
  Future<Donation> createDonation(Donation donation) async {
    try {
      final doc = donation.id.isEmpty
          ? _donations.doc()
          : _donations.doc(donation.id);
      final now = DateTime.now();
      final created = donation.copyWith(
        id: doc.id,
        createdAt: now,
        updatedAt: now,
      );
      await doc.set(created.toMap()).timeout(const Duration(seconds: 20));
      return created;
    } on FirebaseException catch (error) {
      throw AppException(
        'Donation save failed: ${error.code}. ${error.message ?? ''}',
      );
    } on TimeoutException {
      throw const AppException(
        'Donation save timed out. Check internet and Firestore setup.',
      );
    } catch (_) {
      throw const AppException('Unable to create donation.');
    }
  }

  @override
  Future<void> updateDonation(Donation donation) async {
    try {
      await _donations
          .doc(donation.id)
          .set(
            donation.copyWith(updatedAt: DateTime.now()).toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      throw const AppException('Unable to update donation.');
    }
  }

  @override
  Future<void> updateStatus({
    required String donationId,
    required DonationStatus status,
    String? charityId,
    String? charityName,
  }) async {
    try {
      final data = <String, Object?>{
        'status': status.name,
        'acceptedByCharityId': charityId,
        'acceptedByCharityName': charityName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      await _donations.doc(donationId).update(data);
    } catch (_) {
      throw const AppException('Unable to update donation status.');
    }
  }

  @override
  Future<void> deleteDonation(String donationId) async {
    try {
      await _donations.doc(donationId).delete();
    } catch (_) {
      throw const AppException('Unable to delete donation.');
    }
  }

  bool _matchesFilters(
    Donation donation, {
    String? city,
    DonationStatus? status,
  }) {
    final cityMatches =
        city == null ||
        city.trim().isEmpty ||
        donation.city.toLowerCase().contains(city.trim().toLowerCase());
    final statusMatches = status == null || donation.status == status;
    return cityMatches && statusMatches;
  }
}

class DemoDonationService implements DonationService {
  final StreamController<List<Donation>> _controller =
      StreamController<List<Donation>>.broadcast();
  final List<Donation> _donations = <Donation>[];

  @override
  Stream<List<Donation>> watchDonations({
    String? city,
    DonationStatus? status,
  }) async* {
    yield _filtered(city: city, status: status);
    yield* _controller.stream.map((_) => _filtered(city: city, status: status));
  }

  @override
  Stream<List<Donation>> watchDonationsForUser(String userId) async* {
    yield _donationsForUser(userId);
    yield* _controller.stream.map((_) => _donationsForUser(userId));
  }

  @override
  Stream<Donation?> watchDonation(String donationId) async* {
    yield _findDonation(donationId);
    yield* _controller.stream.map((_) => _findDonation(donationId));
  }

  @override
  Future<Donation> createDonation(Donation donation) async {
    final now = DateTime.now();
    final created = donation.copyWith(
      id: donation.id.isEmpty
          ? 'donation-${now.microsecondsSinceEpoch}'
          : donation.id,
      createdAt: now,
      updatedAt: now,
    );
    _donations.add(created);
    _emit();
    return created;
  }

  @override
  Future<void> updateDonation(Donation donation) async {
    final index = _donations.indexWhere((item) => item.id == donation.id);
    if (index == -1) {
      throw const AppException('Donation not found.');
    }
    _donations[index] = donation.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> updateStatus({
    required String donationId,
    required DonationStatus status,
    String? charityId,
    String? charityName,
  }) async {
    final index = _donations.indexWhere((item) => item.id == donationId);
    if (index == -1) {
      throw const AppException('Donation not found.');
    }
    _donations[index] = _donations[index].copyWith(
      status: status,
      acceptedByCharityId: charityId,
      acceptedByCharityName: charityName,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> deleteDonation(String donationId) async {
    _donations.removeWhere((donation) => donation.id == donationId);
    _emit();
  }

  void dispose() {
    _controller.close();
  }

  List<Donation> _filtered({String? city, DonationStatus? status}) {
    final result = _donations.where((donation) {
      final cityMatches =
          city == null ||
          city.trim().isEmpty ||
          donation.city.toLowerCase().contains(city.trim().toLowerCase());
      final statusMatches = status == null || donation.status == status;
      return cityMatches && statusMatches;
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return result;
  }

  List<Donation> _donationsForUser(String userId) {
    return _donations.where((donation) => donation.donorId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Donation? _findDonation(String donationId) {
    for (final donation in _donations) {
      if (donation.id == donationId) {
        return donation;
      }
    }
    return null;
  }

  void _emit() {
    _controller.add(List<Donation>.unmodifiable(_donations));
  }
}