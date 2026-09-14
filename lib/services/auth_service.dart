import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import 'app_database.dart';

class AuthService {
  AuthService(this._database);

  final AppDatabase _database;

  static const int _pbkdf2Iterations = 120000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw AuthException('Please enter your name.');
    }
    if (!_looksLikeEmail(normalizedEmail)) {
      throw AuthException('Please enter a valid email address.');
    }
    final existing = await _database.findUserByEmail(normalizedEmail);
    if (existing != null) {
      throw AuthException('An account with this email already exists.');
    }
    if (password.length < 8) {
      throw AuthException('Use at least 8 characters for the password.');
    }
    return _database.insertUser(
      AppUser(
        id: null,
        name: normalizedName,
        email: normalizedEmail,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final user = await _database.findUserByEmail(email.trim().toLowerCase());
    if (user == null || !_verifyPassword(password, user.passwordHash)) {
      throw AuthException('Email or password is incorrect.');
    }

    if (_isLegacySha256Hash(user.passwordHash) && user.id != null) {
      await _database.updateUserPasswordHash(user.id!, _hashPassword(password));
    }

    return user;
  }

  String _hashPassword(String password) {
    final salt = _randomBytes(_saltLength);
    final key = _pbkdf2Sha256(
      utf8.encode(password),
      salt,
      _pbkdf2Iterations,
      _keyLength,
    );
    return 'pbkdf2_sha256\$$_pbkdf2Iterations\$${base64UrlEncode(salt)}\$${base64UrlEncode(key)}';
  }

  bool _verifyPassword(String password, String storedHash) {
    if (_isLegacySha256Hash(storedHash)) {
      final legacy = sha256.convert(utf8.encode(password)).toString();
      return _constantTimeEquals(utf8.encode(legacy), utf8.encode(storedHash));
    }

    final parts = storedHash.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    try {
      final salt = base64Url.decode(parts[2]);
      final expected = base64Url.decode(parts[3]);
      final actual = _pbkdf2Sha256(
        utf8.encode(password),
        salt,
        iterations,
        expected.length,
      );
      return _constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  List<int> _pbkdf2Sha256(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final blocks = (keyLength / sha256.convert(<int>[]).bytes.length).ceil();
    final output = <int>[];

    for (var block = 1; block <= blocks; block++) {
      var u = hmac.convert([...salt, ..._int32BigEndian(block)]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.addAll(t);
    }

    return output.take(keyLength).toList(growable: false);
  }

  List<int> _int32BigEndian(int value) => [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(
      length,
      (_) => random.nextInt(256),
      growable: false,
    );
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final maxLength = max(a.length, b.length);
    for (var i = 0; i < maxLength; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      diff |= av ^ bv;
    }
    return diff == 0;
  }

  bool _isLegacySha256Hash(String value) {
    final hex = RegExp(r'^[a-fA-F0-9]{64}$');
    return hex.hasMatch(value);
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}
