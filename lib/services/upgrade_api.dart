import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

/// Turning a day pass into a membership.
class UpgradeApi {
  UpgradeApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<String> toMember() async {
    final token = await CardStore.readAuthToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/upgrade'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      },
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not upgrade.');
    }

    // The new card replaces the old one on the device immediately, so the
    // QR works the moment they walk back in — no sign out and in again.
    if (j['card'] != null) {
      await CardStore.saveCard(j['card'] as Map<String, dynamic>);
    }
    if (j['member'] != null) {
      await CardStore.saveMember(j['member'] as Map<String, dynamic>);
    }

    return j['message']?.toString() ?? 'You are a member.';
  }
}
