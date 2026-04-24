import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import '../utils/password_hasher.dart';
import 'database_helper.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<UserProfile?> restoreSession() async {
    return _databaseHelper.getCurrentSessionUser();
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
    String preferredCurrency = 'USD',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const AuthException('Enter a valid email address.');
    }
    if (cleanName.isEmpty) {
      throw const AuthException('Enter your name.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final existingUser = await _databaseHelper.getUserByEmail(normalizedEmail);
    if (existingUser != null) {
      throw const AuthException('An account already exists for this email.');
    }

    final now = DateTime.now();
    final salt = PasswordHasher.createSalt();
    final user = UserProfile(
      email: normalizedEmail,
      displayName: cleanName,
      preferredCurrency: preferredCurrency,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final userId = await _databaseHelper.insertUser(
        user: user,
        passwordHash: PasswordHasher.hashPassword(password, salt),
        passwordSalt: salt,
      );
      final savedUser = user.copyWith(id: userId);
      await _databaseHelper.replaceSession(
        userId: userId,
        token: _createSessionToken(),
      );
      return savedUser;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AuthException('An account already exists for this email.');
      }
      throw const AuthException('Unable to create account.');
    }
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userRecord = await _databaseHelper.getUserAuthByEmail(
      normalizedEmail,
    );

    if (userRecord == null) {
      return signUp(
        email: normalizedEmail,
        password: password,
        displayName: _displayNameFromEmail(normalizedEmail),
      );
    }

    if (!PasswordHasher.verify(
          password: password,
          salt: userRecord.passwordSalt,
          expectedHash: userRecord.passwordHash,
        )) {
      throw const AuthException('Email or password is incorrect.');
    }

    await _databaseHelper.replaceSession(
      userId: userRecord.profile.id!,
      token: _createSessionToken(),
    );
    return userRecord.profile;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await _databaseHelper.updateUserProfile(updatedProfile);
    return updatedProfile;
  }

  Future<void> logout() {
    return _databaseHelper.clearSession();
  }

  String _createSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'User';
    }

    final cleaned = localPart.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim();
    if (cleaned.isEmpty) {
      return 'User';
    }

    return cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
