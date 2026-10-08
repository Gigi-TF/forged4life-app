import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'card_store.dart';

class BlogComment {
  BlogComment(this.name, this.body, this.at, {this.approved = true});

  final String name;
  final String body;
  final DateTime? at;
  final bool approved;

  factory BlogComment.fromJson(Map<String, dynamic> j, {String? fallbackName}) =>
      BlogComment(
        j['name'] as String? ?? fallbackName ?? 'You',
        j['body'] as String? ?? '',
        j['at'] == null ? null : DateTime.tryParse(j['at'] as String)?.toLocal(),
        approved: j['approved'] as bool? ?? true,
      );
}

class CommentsApi {
  CommentsApi({this.baseUrl = Api.base});
  final String baseUrl;

  Future<Map<String, String>> _headers({bool auth = true}) async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth)
          'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  /// Public. Reading comments needs no account — the blog itself does not.
  Future<List<BlogComment>> forPost(String slug) async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/api/f4l/blog/$slug/comments'),
          headers: await _headers(auth: false));

      if (res.statusCode >= 400) return [];

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['comments'] as List)
          .map((e) => BlogComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// The member's own, including ones awaiting approval — so they can see
  /// their comment landed rather than wondering whether it vanished.
  Future<List<BlogComment>> mine(String slug, String name) async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/api/f4l/blog/$slug/comments/mine'),
          headers: await _headers());

      if (res.statusCode >= 400) return [];

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['comments'] as List)
          .map((e) => BlogComment.fromJson(e as Map<String, dynamic>,
              fallbackName: name))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> post(String slug, String body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/blog/$slug/comments'),
      headers: await _headers(),
      body: jsonEncode({'body': body}),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      final errors = j['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        throw Exception((errors.values.first as List).first.toString());
      }
      throw Exception(j['message']?.toString() ?? 'Could not post that.');
    }

    return j['message']?.toString() ?? 'Thank you.';
  }
}
