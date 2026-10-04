/// Third-party design and asset notices ready for the future Credits screen.
abstract final class ThirdPartyCredits {
  static const List<ThirdPartyCredit> entries = <ThirdPartyCredit>[
    ThirdPartyCredit(
      name: 'Lucide',
      notice: 'Badge icons adapted from Lucide',
      license: 'ISC License',
      website: 'https://lucide.dev',
    ),
    ThirdPartyCredit(
      name: 'DiceBear',
      notice: 'Avatar generation library',
      license: 'MIT License',
      website: 'https://www.dicebear.com',
    ),
    ThirdPartyCredit(
      name: 'Open Peeps',
      notice: 'Avatar artwork by Pablo Stanley, remixed by DiceBear',
      license: 'CC0 1.0',
      website: 'https://www.openpeeps.com',
    ),
    ThirdPartyCredit(
      name: 'Phosphor Icons',
      notice: 'App icons use the Phosphor icon family',
      license: 'MIT License',
      website: 'https://phosphoricons.com',
    ),
    ThirdPartyCredit(
      name: 'Baloo 2',
      notice: 'Headings, titles and buttons use the Baloo 2 typeface',
      license: 'SIL Open Font License 1.1',
      website: 'https://github.com/EkType/Baloo2',
    ),
    ThirdPartyCredit(
      name: 'Piper — "alba" voice (en_GB, medium)',
      notice:
          'Onboarding narration synthesized offline with the open-source '
          'Piper text-to-speech voice "alba", trained on Centre for Speech '
          'Technology Voice Cloning Toolkit recordings',
      license: 'CC BY 4.0',
      website: 'https://huggingface.co/rhasspy/piper-voices',
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
