import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Which parts of the app are live.
///
/// Fetched once at startup and held in memory. Server-side so a feature can
/// be switched on with a .env change rather than a new bundle, a Play review
/// and a wait for everyone to update.
class Features {
  Features._();
  static final instance = Features._();

  /*
   * Default to OFF.
   *
   * If the fetch fails — no signal on first launch, server down — a member
   * sees "Opening soon" rather than a live ordering screen for a kitchen
   * that is not taking orders. Greyed out wrongly is recoverable; an order
   * nobody is making is not.
   */
  bool cafeteria = false;
  bool press = false;
  bool rewards = false;
  bool books = false;
  bool sessions = false;

  String soonLabel = 'Opening soon';

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final res = await http
          .get(Uri.parse('${Api.base}/api/f4l/features'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (res.statusCode >= 400) return;

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final f = (j['features'] as Map<String, dynamic>?) ?? {};

      cafeteria = f['cafeteria'] as bool? ?? false;
      press = f['press'] as bool? ?? false;
      rewards = f['rewards'] as bool? ?? false;
      books = f['books'] as bool? ?? false;
      sessions = f['sessions'] as bool? ?? false;

      soonLabel = j['soon_label'] as String? ?? soonLabel;

      _loaded = true;
    } catch (_) {
      // Leave the defaults. A timeout must not block the app from opening.
    }
  }
}
