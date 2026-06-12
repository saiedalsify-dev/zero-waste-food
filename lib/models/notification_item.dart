import '../core/utils/firebase_value.dart';

enum NotificationType {
  newDonation,
  donationAccepted,
  statusUpdate;

  String get label {
    switch (this) {
      case NotificationType.newDonation:
        return 'New donation';
      case NotificationType.donationAccepted:
        return 'Donation accepted';
      case NotificationType.statusUpdate:
        return 'Status update';
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'donationAccepted':
        return NotificationType.donationAccepted;
      case 'statusUpdate':
        return NotificationType.statusUpdate;
      case 'newDonation':
      default:
        return NotificationType.newDonation;
    }
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.relatedDonationId,
    this.read = false,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedDonationId;
  final bool read;
  final DateTime createdAt;

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedDonationId,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedDonationId: relatedDonationId ?? this.relatedDonationId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedDonationId': relatedDonationId,
      'read': read,
      'createdAt': writeFirebaseDate(createdAt),
    };
  }

  factory NotificationItem.fromMap(String id, Map<String, Object?> map) {
    return NotificationItem(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.fromString(map['type'] as String?),
      relatedDonationId: map['relatedDonationId'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: readFirebaseDate(map['createdAt']),
    );
  }
}
