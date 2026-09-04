import 'dart:convert';
import 'package:http/http.dart' as http;

class VisitPurpose {
  VisitPurpose(this.id, this.label, this.isOther);

  final int id;
  final String label;

  /// Reveals the free-text box.
  final bool isOther;

  factory VisitPurpose.fromJson(Map<String, dynamic> j) => VisitPurpose(
        j['id'] as int,
        j['label'] as String,
        j['is_other'] as bool? ?? false,
      );
}

/// The day-pass reasons.
///
/// Fetched rather than hardcoded, so reception can change the list without an
/// app release — which matters, because the useful list is the one that
/// follows what is actually happening in the building.
class PurposesApi {
  PurposesApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<List<VisitPurpose>> all() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/f4l/visit-purposes'),
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode >= 400) return [];

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['purposes'] as List)
          .map((e) => VisitPurpose.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Signup must not fail because a dropdown could not load. The field is
      // optional; an empty list simply hides it.
      return [];
    }
  }
}
