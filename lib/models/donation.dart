import '../core/utils/firebase_value.dart';

enum DonationStatus {
  pending,
  accepted,
  rejected,
  completed;

  String get label {
    switch (this) {
      case DonationStatus.pending:
        return 'Pending';
      case DonationStatus.accepted:
        return 'Accepted';
      case DonationStatus.rejected:
        return 'Rejected';
      case DonationStatus.completed:
        return 'Completed';
    }
  }

  static DonationStatus fromString(String? value) {
    switch (value) {
      case 'accepted':
        return DonationStatus.accepted;
      case 'rejected':
        return DonationStatus.rejected;
      case 'completed':
        return DonationStatus.completed;
      case 'pending':
      default:
        return DonationStatus.pending;
    }
  }
}

class Donation {
  const Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.city,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.acceptedByCharityId,
    this.acceptedByCharityName,
    this.notes,
  });

  final String id;
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final double quantity;
  final String unit;
  final DateTime expiryDate;
  final String city;
  final double? latitude;
  final double? longitude;
  final DonationStatus status;
  final String? acceptedByCharityId;
  final String? acceptedByCharityName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable =>
      status == DonationStatus.pending && !expiryDate.isBefore(DateTime.now());
  bool get hasCoordinates => latitude != null && longitude != null;

  Donation copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? title,
    String? description,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    String? city,
    double? latitude,
    double? longitude,
    DonationStatus? status,
    String? acceptedByCharityId,
    String? acceptedByCharityName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      acceptedByCharityId: acceptedByCharityId ?? this.acceptedByCharityId,
      acceptedByCharityName:
          acceptedByCharityName ?? this.acceptedByCharityName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'title': title,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': writeFirebaseDate(expiryDate),
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'acceptedByCharityId': acceptedByCharityId,
      'acceptedByCharityName': acceptedByCharityName,
      'notes': notes,
      'createdAt': writeFirebaseDate(createdAt),
      'updatedAt': writeFirebaseDate(updatedAt),
    };
  }

  factory Donation.fromMap(String id, Map<String, Object?> map) {
    return Donation(
      id: id,
      donorId: map['donorId'] as String? ?? '',
      donorName: map['donorName'] as String? ?? 'Donor',
      title: map['title'] as String? ?? 'Food donation',
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'Meals',
      expiryDate: readFirebaseDate(map['expiryDate']),
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: DonationStatus.fromString(map['status'] as String?),
      acceptedByCharityId: map['acceptedByCharityId'] as String?,
      acceptedByCharityName: map['acceptedByCharityName'] as String?,
      notes: map['notes'] as String?,
      createdAt: readFirebaseDate(map['createdAt']),
      updatedAt: readFirebaseDate(map['updatedAt']),
    );
  }
}
