import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/credits/third_party_credits.dart';

void main() {
  test('credits the Avataaars artwork and removes Open Peeps', () {
    final avatarCredit = ThirdPartyCredits.entries.singleWhere(
      (entry) => entry.name == 'Avataaars',
    );

    expect(
      avatarCredit.notice,
      'Avataaars by Pablo Stanley, remixed by DiceBear',
    );
    expect(avatarCredit.license, 'Free for personal and commercial use');
    expect(avatarCredit.website, 'https://avataaars.com/');
    expect(
      ThirdPartyCredits.entries.any((entry) => entry.name == 'Open Peeps'),
      isFalse,
    );
  });
}
