import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

/// Email and password auth, replacing the old email-OTP flow.
///
/// Both calls end the same way: a Sanctum token in secure storage and the
/// card secret pulled down, so the QR works offline from the first second.
class AuthApi {
  AuthApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String memberType = 'member',
    String? company,
    int? visitPurposeId,
    String? otherPurpose,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'member_type': memberType,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (company != null && company.isNotEmpty) 'company': company,
        if (visitPurposeId != null) 'visit_purpose_id': visitPurposeId,
        // The free text from "Something else". Goes into `purpose`, which is
        // the column that already held it.
        if (otherPurpose != null && otherPurpose.isNotEmpty)
          'purpose': otherPurpose,
      }),
    );

    return _finish(res);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _finish(res);
  }

  /// Always resolves. The server says the same thing whether or not the
  /// address exists, and so does this.
  Future<void> forgotPassword(String email) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/f4l/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
    } catch (_) {
      // Swallowed on purpose — see above.
    }
  }

  /// Change the password from inside the app, knowing the current one.
  ///
  /// The server keeps THIS session alive and kills every other one — so
  /// changing your password because you think someone else has it does the
  /// thing you meant, without signing you out of the phone in your hand.
  Future<void> changePassword({
    required String current,
    required String password,
  }) async {
    final token = await CardStore.readAuthToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/auth/change-password'),
      headers: {..._headers, 'Authorization': 'Bearer ${token ?? ''}'},
      body: jsonEncode({
        'current': current,
        'password': password,
        'password_confirmation': password,
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception(_messageFrom(res));
    }
  }

  Future<void> logout() async {
    final token = await CardStore.readAuthToken();

    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/api/f4l/auth/logout'),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // If the server cannot be reached, wiping locally still logs them out
        // on this device, which is what they asked for.
      }
    }

    await CardStore.wipe();
  }

  Future<Map<String, dynamic>> _finish(http.Response res) async {
    late Map<String, dynamic> j;
    try {
      j = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Could not reach the Forge. Check your connection.');
    }

    if (res.statusCode >= 400) {
      throw Exception(_messageFrom(res, decoded: j));
    }

    await CardStore.saveAuthToken(j['token'] as String);
    await CardStore.saveMember(j['member'] as Map<String, dynamic>);

    if (j['card'] != null) {
      await CardStore.saveCard(j['card'] as Map<String, dynamic>);
    }

    return j;
  }

  /// Laravel returns field errors under `errors`. Surfacing the first one
  /// beats a generic "the given data was invalid" — the member needs to know
  /// it was the password that was too short, not that something went wrong.
  String _messageFrom(http.Response res, {Map<String, dynamic>? decoded}) {
    late Map<String, dynamic> j;
    try {
      j = decoded ?? jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return 'Could not reach the Forge. Check your connection.';
    }

    final errors = j['errors'] as Map<String, dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      return (errors.values.first as List).first.toString();
    }

    return j['message']?.toString() ?? 'Something went wrong.';
  }
}
