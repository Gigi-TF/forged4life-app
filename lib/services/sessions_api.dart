import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'card_store.dart';

class LaunchSession {
  LaunchSession({
    required this.slug,
    required this.title,
    required this.audience,
    required this.hook,
    required this.dateLabel,
    required this.timeLabel,
    required this.venue,
    required this.isPaid,
    required this.status,
    required this.seatsLeft,
    required this.registered,
    this.price,
    this.myStatus,
    this.forWhom,
    this.explore = const [],
    this.footnote,
    this.capacity,
  });

  final String slug;
  final String title;
  final String audience;
  final String hook;
  final String dateLabel;
  final String timeLabel;
  final String venue;
  final bool isPaid;
  final double? price;

  /// open | nearly_full | full | closed | past
  final String status;
  final int seatsLeft;
  final bool registered;
  final String? myStatus;

  final String? forWhom;
  final List<String> explore;
  final String? footnote;
  final int? capacity;

  bool get isWaitlisted => myStatus == 'waitlisted';
  bool get canRegister =>
      !registered && (status == 'open' || status == 'nearly_full' || status == 'full');

  factory LaunchSession.fromJson(Map<String, dynamic> j) => LaunchSession(
        slug: j['slug'] as String,
        title: j['title'] as String,
        audience: j['audience'] as String? ?? '',
        hook: j['hook'] as String? ?? '',
        dateLabel: j['date_label'] as String? ?? '',
        timeLabel: j['time_label'] as String? ?? '',
        venue: j['venue'] as String? ?? '',
        isPaid: j['is_paid'] as bool? ?? false,
        price: (j['price'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'open',
        seatsLeft: (j['seats_left'] as num?)?.toInt() ?? 0,
        registered: j['registered'] as bool? ?? false,
        myStatus: j['my_status'] as String?,
        forWhom: j['for_whom'] as String?,
        explore: ((j['explore'] as List?) ?? []).map((e) => e.toString()).toList(),
        footnote: j['footnote'] as String?,
        capacity: (j['capacity'] as num?)?.toInt(),
      );
}

class MyRegistration {
  MyRegistration(this.reference, this.status, this.label, this.url);

  final String reference;
  final String status;
  final String label;
  final String? url;

  factory MyRegistration.fromJson(Map<String, dynamic> j) => MyRegistration(
        j['reference'] as String,
        j['status'] as String,
        j['label'] as String? ?? '',
        j['url'] as String?,
      );
}

class SessionsApi {
  SessionsApi({this.baseUrl = Api.base});
  final String baseUrl;

  Future<Map<String, String>> _headers() async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  Future<List<LaunchSession>> all() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/sessions'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load the sessions.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['sessions'] as List)
        .map((e) => LaunchSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({LaunchSession session, MyRegistration? mine})> one(String slug) async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/sessions/$slug'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load that session.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      session: LaunchSession.fromJson(j['session'] as Map<String, dynamic>),
      mine: j['registration'] == null
          ? null
          : MyRegistration.fromJson(j['registration'] as Map<String, dynamic>),
    );
  }

  Future<({String reference, String status, String message})> register(
      String slug) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/sessions/$slug/register'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not register.');
    }

    return (
      reference: j['reference'].toString(),
      status: j['status'].toString(),
      message: j['message'].toString(),
    );
  }

  Future<String> cancel(String slug) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/sessions/$slug/cancel'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not cancel.');
    }

    return j['message']?.toString() ?? 'Cancelled.';
  }
}
