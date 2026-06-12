import '../core/utils/firebase_value.dart';

enum UserRole {
  donor,
  charity,
  admin;

  String get label {
    switch (this) {
      case UserRole.donor:
        return 'Donor';
      case UserRole.charity:
        return 'Charity';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'charity':
        return UserRole.charity;
      case 'admin':
        return UserRole.admin;
      case 'donor':
      default:
        return UserRole.donor;
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.city,
    required this.createdAt,
    this.phone,
    this.fcmToken,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String city;
  final DateTime createdAt;
  final String? phone;
  final String? fcmToken;

  bool get isDonor => role == UserRole.donor;
  bool get isCharity => role == UserRole.charity;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? city,
    DateTime? createdAt,
    String? phone,
    String? fcmToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'city': city,
      'phone': phone,
      'fcmToken': fcmToken,
      'createdAt': writeFirebaseDate(createdAt),
    };
  }

  factory AppUser.fromMap(String id, Map<String, Object?> map) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      city: map['city'] as String? ?? '',
      phone: map['phone'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: readFirebaseDate(map['createdAt']),
    );
  }
}
