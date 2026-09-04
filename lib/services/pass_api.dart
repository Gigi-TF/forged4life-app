import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class MyPass {
  MyPass({
    required this.reference,
    required this.name,
    required this.dateLabel,
    required this.valid,
    required this.url,
    this.validUntil,
    this.room,
    this.purpose,
    this.company,
    this.vehicle,
  });

  final String reference;
  final String name;
  final String dateLabel;
  final bool valid;
  final String url;
  final String? validUntil;
  final String? room;
  final String? purpose;
  final String? company;
  final String? vehicle;

  String get untilLabel =>
      validUntil == null ? '23:59 tonight' : '$validUntil tonight';

  factory MyPass.fromJson(Map<String, dynamic> j) => MyPass(
        reference: j['reference'] as String,
        name: j['name'] as String? ?? '',
        dateLabel: j['date_label'] as String? ?? '',
        valid: j['valid'] as bool? ?? false,
        url: j['url'] as String? ?? '',
        validUntil: j['valid_until'] as String?,
        room: j['room'] as String?,
        purpose: j['purpose'] as String?,
        company: j['company'] as String?,
        vehicle: j['vehicle'] as String?,
      );
}

class PassApi {
  PassApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  /// Null when this member has no day visit — which is every full member.
  Future<MyPass?> mine() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/f4l/my-pass'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
        },
      );

      if (res.statusCode >= 400) return null;

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return j['pass'] == null
          ? null
          : MyPass.fromJson(j['pass'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
