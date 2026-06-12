import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../core/config/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> getCurrentUser();
  Future<void> signIn({required String email, required String password});
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String city,
    String? phone,
  });
  Future<void> updateProfile(AppUser user);
  Future<List<AppUser>> fetchUsers();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth, this._firestore);

  static const Duration _operationTimeout = Duration(seconds: 20);

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirebaseCollections.users);

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return _loadOrCreateUser(firebaseUser);
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return _loadOrCreateUser(firebaseUser);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(_operationTimeout);
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AppException(_authErrorMessage(error));
    } catch (_) {
      throw const AppException('Unable to sign in. Please try again.');
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String city,
    String? phone,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_operationTimeout);
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AppException('Registration failed. Please try again.');
      }

      await firebaseUser
          .updateDisplayName(name.trim())
          .timeout(_operationTimeout);
      final appUser = AppUser(
        id: firebaseUser.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        city: city.trim(),
        phone: phone?.trim(),
        createdAt: DateTime.now(),
      );
      await _users
          .doc(appUser.id)
          .set(appUser.toMap())
          .timeout(_operationTimeout);
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AppException(_authErrorMessage(error));
    } on TimeoutException {
      throw const AppException(
        'Firebase is taking too long. Check your internet, Firebase Auth, and Firestore setup.',
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Unable to create account. Please try again.');
    }
  }

  @override
  Future<void> updateProfile(AppUser user) async {
    try {
      await _users
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(_operationTimeout);
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null) {
        await currentFirebaseUser
            .updateDisplayName(user.name)
            .timeout(_operationTimeout);
      }
    } catch (_) {
      throw const AppException('Unable to update profile.');
    }
  }

  @override
  Future<List<AppUser>> fetchUsers() async {
    try {
      final snapshot = await _users.get().timeout(_operationTimeout);
      final users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    } on TimeoutException {
      throw const AppException('Users load timed out. Check Firebase setup.');
    } catch (_) {
      throw const AppException(
        'Unable to load users. Check Firebase permissions and try again.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _loadOrCreateUser(firebase_auth.User firebaseUser) async {
    try {
      final snapshot = await _users
          .doc(firebaseUser.uid)
          .get()
          .timeout(_operationTimeout);
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromMap(snapshot.id, snapshot.data()!);
      }

      final fallback = _fallbackUserFromFirebase(firebaseUser);
      await _users
          .doc(fallback.id)
          .set(fallback.toMap())
          .timeout(_operationTimeout);
      return fallback;
    } catch (_) {
      return _fallbackUserFromFirebase(firebaseUser);
    }
  }

  AppUser _fallbackUserFromFirebase(firebase_auth.User firebaseUser) {
    final email = firebaseUser.email ?? '';
    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: email,
      role: _roleFromEmail(email),
      city: AppConstants.defaultCity,
      createdAt: DateTime.now(),
    );
  }

  UserRole _roleFromEmail(String email) {
    final normalized = email.toLowerCase();
    if (normalized.contains('admin')) {
      return UserRole.admin;
    }
    if (normalized.contains('charity')) {
      return UserRole.charity;
    }
    return UserRole.donor;
  }

  String _authErrorMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class DemoAuthService implements AuthService {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  final Map<String, AppUser> _usersByEmail = <String, AppUser>{};
  final Map<String, String> _passwordsByEmail = <String, String>{};
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;

  @override
  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _usersByEmail[normalizedEmail];
    final expectedPassword = _passwordsByEmail[normalizedEmail];
    if (user == null || expectedPassword != password) {
      throw const AppException('Invalid email or password.');
    }
    _currentUser = user;
    _controller.add(_currentUser);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String city,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail)) {
      throw const AppException('This email is already registered.');
    }

    final user = AppUser(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      role: role,
      city: city.trim(),
      phone: phone?.trim(),
      createdAt: DateTime.now(),
    );
    _usersByEmail[normalizedEmail] = user;
    _passwordsByEmail[normalizedEmail] = password;
    _currentUser = user;
    _controller.add(_currentUser);
  }

  @override
  Future<void> updateProfile(AppUser user) async {
    _usersByEmail[user.email.toLowerCase()] = user;
    if (_currentUser?.id == user.id) {
      _currentUser = user;
      _controller.add(_currentUser);
    }
  }

  @override
  Future<List<AppUser>> fetchUsers() async {
    return _usersByEmail.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}