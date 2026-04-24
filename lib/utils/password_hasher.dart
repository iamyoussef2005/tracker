import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static String createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPassword(String password, String salt) {
    var digest = utf8.encode('$salt:$password');
    for (var i = 0; i < 12000; i++) {
      digest = Uint8List.fromList(sha256.convert(digest).bytes);
    }
    return base64UrlEncode(digest);
  }

  static bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    return hashPassword(password, salt) == expectedHash;
  }
}
