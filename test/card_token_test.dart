import 'package:flutter_test/flutter_test.dart';
import 'package:forged4life/services/card_token.dart';

void main() {
  // THE most important test in this project.
  //
  // Generate the expected value once from Laravel tinker:
  //
  //   $card = App\Models\MembershipCard::first();
  //   app(App\Services\CardTokenService::class)->issue($card, 29000000);
  //
  // Paste the uid, secret and resulting token below. If this test ever fails,
  // stop — do not ship. Every card in circulation depends on these matching.
  test('Dart token matches the PHP implementation', () {
    const uid = '852ea8f4-4a2a-439d-b2fe-4652e2b17bf5';
    const secret =
        'ca1afef819ac4def1f4e1b751b7a2556b0728e5de7e5930a4672e3baf0859a02';
    const expected =
        'F4L1|852ea8f4-4a2a-439d-b2fe-4652e2b17bf5|2|29000000|8EAA9DEE13';

    expect(
      CardToken.issue(
          uid: uid, version: 2, secretHex: secret, counter: 29000000),
      expected,
    );
  });
}
