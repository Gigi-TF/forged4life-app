import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class F4LEvent {
  F4LEvent({
    required this.id,
    required this.title,
    required this.kind,
    this.startsAt,
    this.venue,
    this.open = false,
    this.membersOnly = false,
    this.capacity,
    this.seatsLeft,
    this.closesAt,
    this.myStatus,
    this.description,
  });

  final int id;
  final String title;
  final String kind;
  final DateTime? startsAt;
  final String? venue;
  final bool open;
  final bool membersOnly;
  final int? capacity;
  final int? seatsLeft;
  final DateTime? closesAt;

  /// null | 'registered' | 'waitlisted'
  final String? myStatus;
  final String? description;

  bool get isGoing => myStatus == 'registered';
  bool get isWaitlisted => myStatus == 'waitlisted';
  bool get isFull => seatsLeft != null && seatsLeft! <= 0;
  bool get hasClosed =>
      closesAt != null && closesAt!.isBefore(DateTime.now());

  /// Whether the button should do anything at all.
  bool get canRegister =>
      open && !hasClosed && (startsAt?.isAfter(DateTime.now()) ?? true);

  String get day => startsAt == null ? '--' : startsAt!.day.toString().padLeft(2, '0');

  String get month {
    if (startsAt == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return m[startsAt!.month - 1];
  }

  String get timeLine {
    if (startsAt == null) return venue ?? '';
    final t = '${startsAt!.hour.toString().padLeft(2, '0')}:'
        '${startsAt!.minute.toString().padLeft(2, '0')}';
    return venue == null ? t : '$t · $venue';
  }

  factory F4LEvent.fromJson(Map<String, dynamic> j) => F4LEvent(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        kind: j['kind'] as String? ?? 'Event',
        startsAt: j['starts_at'] == null
            ? null
            : DateTime.tryParse(j['starts_at'] as String)?.toLocal(),
        venue: j['venue'] as String?,
        open: j['open'] as bool? ?? false,
        membersOnly: j['members_only'] as bool? ?? false,
        capacity: (j['capacity'] as num?)?.toInt(),
        seatsLeft: (j['seats_left'] as num?)?.toInt(),
        closesAt: j['closes_at'] == null
            ? null
            : DateTime.tryParse(j['closes_at'] as String)?.toLocal(),
        myStatus: j['my_status'] as String?,
        description: j['description'] as String?,
      );
}

class EventApi {
  EventApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final t = await CardStore.readAuthToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // Sent when we have it — the list is public, but including the token
      // is what makes "you're going" show up.
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<List<F4LEvent>> upcoming() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/events'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load events.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['events'] as List)
        .map((e) => F4LEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<F4LEvent> show(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/events/$id'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not load that event.');
    }
    return F4LEvent.fromJson(j['event'] as Map<String, dynamic>);
  }

  /// Returns 'registered' or 'waitlisted'.
  Future<({String status, String message})> register(int id,
      {int guests = 0}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/f4l/events/$id/register'),
      headers: await _headers(),
      body: jsonEncode({'guests': guests}),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not register.');
    }

    return (
      status: j['status']?.toString() ?? 'registered',
      message: j['message']?.toString() ?? 'Registered.',
    );
  }

  Future<void> cancel(int id) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/events/$id/cancel'),
        headers: await _headers());

    if (res.statusCode >= 400) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(j['message']?.toString() ?? 'Could not cancel.');
    }
  }
}
