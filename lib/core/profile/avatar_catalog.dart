abstract final class AvatarCatalog {
  static const List<String> ids = <String>[
    'avatar-01',
    'avatar-02',
    'avatar-03',
    'avatar-04',
    'avatar-05',
    'avatar-06',
    'avatar-07',
    'avatar-08',
    'avatar-09',
    'avatar-10',
    'avatar-11',
    'avatar-12',
  ];

  static const String autoAssignedId = 'avatar-07';

  static String assetFor(String id) => 'assets/avatars/$id.svg';
}
