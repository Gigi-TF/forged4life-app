import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'card_store.dart';

class TierStep {
  TierStep(this.key, this.label, this.threshold, this.discount,
      this.current, this.reached);

  final String key;
  final String label;
  final int threshold;
  final int discount;
  final bool current;
  final bool reached;

  factory TierStep.fromJson(Map<String, dynamic> j) => TierStep(
        j['key'] as String,
        j['label'] as String,
        (j['threshold'] as num?)?.toInt() ?? 0,
        (j['discount'] as num?)?.toInt() ?? 0,
        j['current'] as bool? ?? false,
        j['reached'] as bool? ?? false,
      );
}

class EarnRule {
  EarnRule(this.label, this.detail, this.points, this.repeat);

  final String label;
  final String detail;
  final int points;
  final String repeat;

  factory EarnRule.fromJson(Map<String, dynamic> j) => EarnRule(
        j['label'] as String,
        j['detail'] as String? ?? '',
        (j['points'] as num?)?.toInt() ?? 0,
        j['repeat'] as String? ?? '',
      );
}

class TierInfo {
  TierInfo(this.loyalty, this.lifetime, this.tiers, this.earn);

  final bool loyalty;
  final int lifetime;
  final List<TierStep> tiers;
  final List<EarnRule> earn;

  factory TierInfo.fromJson(Map<String, dynamic> j) => TierInfo(
        j['loyalty'] as bool? ?? true,
        (j['lifetime'] as num?)?.toInt() ?? 0,
        (j['tiers'] as List)
            .map((e) => TierStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        (j['earn'] as List)
            .map((e) => EarnRule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TiersApi {
  TiersApi({this.baseUrl = Api.base});
  final String baseUrl;

  Future<TierInfo> load() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/f4l/loyalty/tiers'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await CardStore.readAuthToken() ?? ''}',
      },
    );

    if (res.statusCode >= 400) {
      throw Exception('Could not load the tiers.');
    }

    return TierInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
