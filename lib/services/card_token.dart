import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Dart half of App\Services\CardTokenService.
///
/// HMAC-SHA256 over "uid|version|counter", key = raw bytes of the hex secret,
/// first 10 hex chars, uppercased.  Token: F4L1|uid|version|counter|SIG
///
/// If this ever drifts from the PHP side, EVERY card in circulation stops
/// scanning at once. Pin it with a test before you build any UI.
class CardToken {
  static const int period = 60;

  static int counterNow() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;

  static int secondsRemaining() =>
      period - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % period;

  static String issue({
    required String uid,
    required int version,
    required String secretHex,
    int? counter,
  }) {
    final c = counter ?? counterNow();
    final mac = Hmac(sha256, _hex(secretHex)).convert(utf8.encode('$uid|$version|$c'));
    return 'F4L1|$uid|$version|$c|${mac.toString().substring(0, 10).toUpperCase()}';
  }

  static List<int> _hex(String h) =>
      [for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)];
}
