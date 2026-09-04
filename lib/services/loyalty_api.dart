import 'dart:convert';
import 'package:http/http.dart' as http;
import 'card_store.dart';

class Tier {
  Tier(this.key, this.label, this.rank, this.discount);
  final String key;
  final String label;
  final int rank;
  final int discount;

  /// A day pass has no tier at all — rank 0, not "the lowest one".
  bool get none => key == 'none';

  factory Tier.fromJson(Map<String, dynamic> j) => Tier(
        j['key'] as String,
        j['label'] as String,
        (j['rank'] as num).toInt(),
        (j['discount'] as num).toInt(),
      );
}

class NextTier {
  NextTier(this.label, this.discount, this.pointsToGo, this.progress);
  final String label;
  final int discount;
  final int pointsToGo;
  final double progress;

  factory NextTier.fromJson(Map<String, dynamic> j) => NextTier(
        j['label'] as String,
        (j['discount'] as num).toInt(),
        (j['points_to_go'] as num).toInt(),
        (j['progress'] as num).toDouble().clamp(0, 1),
      );
}

class LedgerEntry {
  LedgerEntry(this.delta, this.title, this.reason, this.at);
  final int delta;
  final String title;
  final String reason;
  final DateTime? at;

  String get dateLabel {
    if (at == null) return '';
    final d = DateTime.now().difference(at!);
    if (d.inDays > 30) return '${(d.inDays / 30).floor()} months ago';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return 'Just now';
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        (j['delta'] as num).toInt(),
        j['title'] as String,
        j['reason'] as String? ?? '',
        j['at'] == null
            ? null
            : DateTime.tryParse(j['at'] as String)?.toLocal(),
      );
}

class Reward {
  Reward({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.cost,
    required this.valueLabel,
    required this.minTierRank,
    required this.minTierLabel,
  });

  final int id;
  final String title;
  final String category;
  final String description;
  final int cost;
  final String valueLabel;
  final int minTierRank;
  final String minTierLabel;

  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
        id: j['id'] as int,
        title: j['title'] as String,
        category: j['category'] as String? ?? '',
        description: j['description'] as String? ?? '',
        cost: (j['cost'] as num).toInt(),
        valueLabel: j['value_label'] as String? ?? '',
        minTierRank: (j['min_tier_rank'] as num?)?.toInt() ?? 1,
        // Matches the renamed ladder — ember, flame, blaze, forge.
        minTierLabel: j['min_tier_label'] as String? ?? 'Ember',
      );
}

class RedemptionCode {
  RedemptionCode(this.code, this.title, this.spent, this.status, this.label,
      this.at, this.usedAt);

  final String code;
  final String title;
  final int spent;
  final String status;
  final String label;
  final DateTime? at;
  final DateTime? usedAt;

  bool get unused => status == 'issued';

  factory RedemptionCode.fromJson(Map<String, dynamic> j) => RedemptionCode(
        j['code'] as String,
        j['title'] as String,
        (j['spent'] as num).toInt(),
        j['status'] as String,
        j['label'] as String,
        j['at'] == null
            ? null
            : DateTime.tryParse(j['at'] as String)?.toLocal(),
        j['used_at'] == null
            ? null
            : DateTime.tryParse(j['used_at'] as String)?.toLocal(),
      );
}

/// The rates a day visitor is shown on the upgrade pitch.
///
/// Straight from the server's config, so what the app promises can never
/// drift from what membership actually pays.
class MemberPerks {
  MemberPerks({
    required this.signup,
    required this.checkIn,
    required this.visit,
    required this.discount,
    required this.topDiscount,
  });

  final int signup;
  final int checkIn;
  final int visit;
  final int discount;
  final int topDiscount;

  /// Used only if the server sent nothing. The screen should still say
  /// something sensible rather than crash on a null.
  factory MemberPerks.fallback() => MemberPerks(
        signup: 100,
        checkIn: 25,
        visit: 40,
        discount: 5,
        topDiscount: 20,
      );

  factory MemberPerks.fromJson(Map<String, dynamic> j) => MemberPerks(
        signup: (j['signup'] as num?)?.toInt() ?? 100,
        checkIn: (j['check_in'] as num?)?.toInt() ?? 25,
        visit: (j['visit'] as num?)?.toInt() ?? 40,
        discount: (j['discount'] as num?)?.toInt() ?? 5,
        topDiscount: (j['top_discount'] as num?)?.toInt() ?? 20,
      );
}

/// What Home needs, in one call.
class LoyaltySummary {
  LoyaltySummary({
    required this.name,
    required this.loyalty,
    required this.points,
    required this.lifetime,
    required this.tier,
    required this.checkedInToday,
    required this.checkInPoints,
    required this.visitPoints,
    required this.recent,
    required this.featured,
    required this.unusedCodes,
    this.next,
    this.perks,
  });

  final String name;

  /// False for a day pass. The app shows the upgrade pitch instead of a
  /// balance of zero and a progress bar that never moves.
  final bool loyalty;

  final int points;
  final int lifetime;
  final Tier tier;
  final NextTier? next;
  final bool checkedInToday;
  final int checkInPoints;
  final int visitPoints;
  final List<LedgerEntry> recent;
  final List<Reward> featured;
  final int unusedCodes;

  /// Only sent when [loyalty] is false.
  final MemberPerks? perks;

  String get firstName =>
      name.trim().isEmpty ? 'there' : name.trim().split(' ').first;

  factory LoyaltySummary.fromJson(Map<String, dynamic> j) => LoyaltySummary(
        name: j['name'] as String? ?? '',

        // Defaults to TRUE on purpose. If an older server build does not send
        // the field, a member should keep seeing their sparks — failing the
        // other way would blank the loyalty screen for everyone.
        loyalty: j['loyalty'] as bool? ?? true,

        points: (j['points'] as num?)?.toInt() ?? 0,
        lifetime: (j['lifetime'] as num?)?.toInt() ?? 0,
        tier: Tier.fromJson(j['tier'] as Map<String, dynamic>),
        next: j['next'] == null
            ? null
            : NextTier.fromJson(j['next'] as Map<String, dynamic>),
        checkedInToday: j['checked_in_today'] as bool? ?? false,
        checkInPoints: (j['check_in_points'] as num?)?.toInt() ?? 25,
        visitPoints: (j['visit_points'] as num?)?.toInt() ?? 40,
        recent: ((j['recent'] as List?) ?? [])
            .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        featured: ((j['featured'] as List?) ?? [])
            .map((e) => Reward.fromJson(e as Map<String, dynamic>))
            .toList(),
        unusedCodes: (j['unused_codes'] as num?)?.toInt() ?? 0,
        perks: j['member_perks'] == null
            ? null
            : MemberPerks.fromJson(j['member_perks'] as Map<String, dynamic>),
      );
}

class LoyaltyApi {
  LoyaltyApi({this.baseUrl = 'http://127.0.0.1:8000'});
  final String baseUrl;

  Future<Map<String, String>> _headers() async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      };

  Future<LoyaltySummary> summary() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/loyalty'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load your sparks.');

    return LoyaltySummary.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<String> checkIn() async {
    final res = await http.post(Uri.parse('$baseUrl/api/f4l/loyalty/check-in'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not check in.');
    }
    return j['message']?.toString() ?? 'Checked in.';
  }

  Future<({List<Reward> rewards, int points, Tier tier})> store() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/loyalty/rewards'),
        headers: await _headers());

    if (res.statusCode >= 400) throw Exception('Could not load the store.');

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      rewards: (j['rewards'] as List)
          .map((e) => Reward.fromJson(e as Map<String, dynamic>))
          .toList(),
      points: (j['points'] as num).toInt(),
      tier: Tier.fromJson(j['tier'] as Map<String, dynamic>),
    );
  }

  Future<({String code, String title})> redeem(int rewardId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/loyalty/redeem/$rewardId'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not redeem that.');
    }
    return (code: j['code'].toString(), title: j['title'].toString());
  }

  Future<({String code, String title})> redeemMenuItem(int itemId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/loyalty/redeem-item/$itemId'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not redeem that.');
    }
    return (code: j['code'].toString(), title: j['title'].toString());
  }

  Future<List<RedemptionCode>> myCodes() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/loyalty/codes'),
        headers: await _headers());

    if (res.statusCode >= 400) return [];

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['codes'] as List)
        .map((e) => RedemptionCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({int balance, int lifetime, List<LedgerEntry> entries})>
      activity() async {
    final res = await http.get(Uri.parse('$baseUrl/api/f4l/loyalty/activity'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      balance: (j['balance'] as num).toInt(),
      lifetime: (j['lifetime'] as num).toInt(),
      entries: (j['entries'] as List)
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<String> claimProgramme(String slug) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/f4l/loyalty/claim/$slug'),
        headers: await _headers());

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(j['message']?.toString() ?? 'Could not claim that.');
    }
    return j['message']?.toString() ?? 'Claimed.';
  }
}
