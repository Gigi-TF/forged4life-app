import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class InterestResult {
  InterestResult({
    required this.message,
    required this.newSlugs,
    required this.emailed,
  });

  final String message;
  final List<String> newSlugs;
  final bool emailed;
}

/// Programme interest — what a member has ticked, and saving new ticks.
class InterestApi {
  InterestApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<Map<String, String>> _headers() async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  /// Everything this member has already ticked, so the boxes come back
  /// checked rather than blank.
  Future<Set<String>> mine() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/f4l/interests'),
          headers: await _headers());

      if (res.statusCode >= 400) return {};

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['slugs'] as List).map((e) => e.toString()).toSet();
    } catch (_) {
      // Offline is not an error here — the screen still works, the boxes
      // just start empty.
      return {};
    }
  }

  Future<InterestResult> save(List<String> slugs, {String? forge}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/interests'),
      headers: await _headers(),
      body: jsonEncode({'slugs': slugs, if (forge != null) 'forge': forge}),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not save that.');
    }

    return InterestResult(
      message: j['message']?.toString() ?? 'Saved.',
      newSlugs:
          ((j['new'] as List?) ?? []).map((e) => e.toString()).toList(),
      emailed: j['emailed'] as bool? ?? false,
    );
  }

  Future<void> remove(String slug) async {
    await http.delete(Uri.parse('$baseUrl/api/f4l/interests/$slug'),
        headers: await _headers());
  }
}
