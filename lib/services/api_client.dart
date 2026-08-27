import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class ApiException implements Exception {
  ApiException(this.message, this.status, [this.data]);
  final String message;
  final int status;
  final Map<String, dynamic>? data;
  @override
  String toString() => message;
}

/// Talks to the Laravel backend.
///
/// Change [baseUrl] to your machine's LAN address when testing on a phone —
/// 127.0.0.1 on the device means the device, not your laptop.
class ApiClient {
  ApiClient({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authed = true,
  }) async {
    final token = authed ? await CardStore.readAuthToken() : null;
    final uri = Uri.parse('$baseUrl/api/f4l/$path');

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    late http.Response res;
    try {
      res = method == 'GET'
          ? await http.get(uri, headers: headers)
          : await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    } catch (_) {
      throw ApiException('Could not reach the Forge. Check your connection.', 0);
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected response from the server.', res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Something went wrong.',
        res.statusCode,
        decoded,
      );
    }

    return decoded;
  }

  /// Step 1 — email a six-digit code. Returns whether this address is new.
  Future<bool> requestCode(String email) async {
    final data = await _send('POST', 'auth/otp',
        body: {'email': email}, authed: false);
    return data['is_new'] == true;
  }

  /// Step 2 — exchange the code for a token. Signup fields are sent only the
  /// first time; the server ignores them for an existing member.
  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
    String? name,
    String? phone,
    String? memberType,
    String? ageGroup,
    String? company,
    List<String>? interests,
    String? transitionStage,
  }) async {
    final data = await _send('POST', 'auth/verify', authed: false, body: {
      'email': email,
      'code': code,
      if (name != null) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (memberType != null) 'member_type': memberType,
      if (ageGroup != null) 'age_group': ageGroup,
      if (company != null && company.isNotEmpty) 'company': company,
      if (interests != null && interests.isNotEmpty) 'interests': interests,
      if (transitionStage != null) 'transition_stage': transitionStage,
    });

    await CardStore.saveAuthToken(data['token'] as String);
    return data;
  }

  /// Pulls the card secret once, straight into secure storage. After this the
  /// card generates codes with no network at all.
  Future<Map<String, dynamic>> bootstrapCard() async {
    final data = await _send('GET', 'card/bootstrap');
    await CardStore.saveCard(data['card'] as Map<String, dynamic>);
    return data;
  }

  Future<void> freezeCard() async {
    await _send('POST', 'card/freeze');
    await CardStore.wipe();
  }
}
