import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class NextTier {
  NextTier({
    required this.label,
    required this.discount,
    required this.monthsNeeded,
    required this.monthsHave,
    required this.visitsNeeded,
    required this.visitsHave,
    required this.windowDays,
  });

  final String label;
  final int discount;
  final int monthsNeeded;
  final int monthsHave;
  final int visitsNeeded;
  final int visitsHave;
  final int windowDays;

  double get monthsProgress =>
      monthsNeeded == 0 ? 1 : (monthsHave / monthsNeeded).clamp(0, 1);
  double get visitsProgress =>
      visitsNeeded == 0 ? 1 : (visitsHave / visitsNeeded).clamp(0, 1);

  bool get monthsMet => monthsHave >= monthsNeeded;
  bool get visitsMet => visitsHave >= visitsNeeded;

  factory NextTier.fromJson(Map<String, dynamic> j) => NextTier(
        label: j['label'] as String,
        discount: (j['discount'] as num).toInt(),
        monthsNeeded: (j['months_needed'] as num).toInt(),
        monthsHave: (j['months_have'] as num).toInt(),
        visitsNeeded: (j['visits_needed'] as num).toInt(),
        visitsHave: (j['visits_have'] as num).toInt(),
        windowDays: (j['window_days'] as num).toInt(),
      );
}

class Rung {
  Rung(this.label, this.months, this.visits, this.windowDays, this.discount,
      this.tier);
  final String label;
  final int months;
  final int visits;
  final int windowDays;
  final int discount;
  final String tier;

  factory Rung.fromJson(Map<String, dynamic> j) => Rung(
        j['label'] as String,
        (j['months'] as num).toInt(),
        (j['visits'] as num).toInt(),
        (j['window_days'] as num).toInt(),
        (j['discount'] as num).toInt(),
        j['tier'] as String,
      );
}

class Rewards {
  Rewards({
    required this.tier,
    required this.label,
    required this.discount,
    required this.founding,
    required this.sparks,
    required this.savedTotal,
    required this.savedYear,
    required this.visitsTotal,
    required this.ladder,
    this.next,
  });

  final String tier;
  final String label;
  final int discount;
  final bool founding;
  final int sparks;
  final double savedTotal;
  final double savedYear;
  final int visitsTotal;
  final List<Rung> ladder;
  final NextTier? next;

  factory Rewards.fromJson(Map<String, dynamic> j) {
    final t = j['tier'] as Map<String, dynamic>;
    return Rewards(
      tier: t['tier'] as String,
      label: t['label'] as String,
      discount: (t['discount'] as num).toInt(),
      founding: t['founding'] as bool? ?? false,
      next: t['next'] == null
          ? null
          : NextTier.fromJson(t['next'] as Map<String, dynamic>),
      sparks: (j['sparks'] as num).toInt(),
      savedTotal: (j['saved_total'] as num).toDouble(),
      savedYear: (j['saved_year'] as num).toDouble(),
      visitsTotal: (j['visits_total'] as num).toInt(),
      ladder: (j['ladder'] as List)
          .map((e) => Rung.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LedgerEntry {
  LedgerEntry(this.delta, this.balance, this.label, this.note, this.at);
  final int delta;
  final int balance;
  final String label;
  final String? note;
  final DateTime? at;

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        (j['delta'] as num).toInt(),
        (j['balance'] as num).toInt(),
        j['label'] as String,
        j['note'] as String?,
        j['at'] == null ? null : DateTime.tryParse(j['at'] as String)?.toLocal(),
      );
}

class RewardsApi {
  RewardsApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<Map<String, String>> _headers() async => {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  Future<Rewards> summary() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/rewards'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load your rewards.');

    return Rewards.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<LedgerEntry>> activity() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/rewards/activity'),
        headers: await _headers());

    if (res.statusCode >= 400) return [];

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['entries'] as List)
        .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
