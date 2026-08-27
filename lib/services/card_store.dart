import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The card secret lives in Android Keystore / iOS Keychain — hardware-backed
/// where the device supports it. This is the main thing native buys us over a
/// web app, where any script on the origin could read IndexedDB.
class CardStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _cardKey = 'f4l_card';
  static const _authKey = 'f4l_token';
  static const _memberKey = 'f4l_member';

  static Future<void> saveCard(Map<String, dynamic> card) =>
      _storage.write(key: _cardKey, value: jsonEncode(card));

  static Future<Map<String, dynamic>?> readCard() async {
    final raw = await _storage.read(key: _cardKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveMember(Map<String, dynamic> m) =>
      _storage.write(key: _memberKey, value: jsonEncode(m));

  static Future<Map<String, dynamic>?> readMember() async {
    final raw = await _storage.read(key: _memberKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveAuthToken(String t) => _storage.write(key: _authKey, value: t);
  static Future<String?> readAuthToken() => _storage.read(key: _authKey);

  /// Logout, or "I lost my phone". Wipes the secret from the device.
  static Future<void> wipe() async {
    await _storage.delete(key: _cardKey);
    await _storage.delete(key: _authKey);
    await _storage.delete(key: _memberKey);
  }
}
