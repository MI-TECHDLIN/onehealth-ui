/// Third-party design and asset notices ready for the future Credits screen.
abstract final class ThirdPartyCredits {
  static const List<ThirdPartyCredit> entries = <ThirdPartyCredit>[
    ThirdPartyCredit(
      name: 'Lucide',
      notice: 'Badge icons adapted from Lucide',
      license: 'ISC License',
      website: 'https://lucide.dev',
    ),
  ];
}

class ThirdPartyCredit {
  const ThirdPartyCredit({
    required this.name,
    required this.notice,
    required this.license,
    required this.website,
  });

  final String name;
  final String notice;
  final String license;
  final String website;
}
