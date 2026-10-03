class AuthUser {
  const AuthUser({required this.username, required this.displayName});

  final String username;
  final String displayName;
}

class StreamSite {
  const StreamSite({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String code;
  final String name;
  final double latitude;
  final double longitude;
}

class ReferenceValue {
  const ReferenceValue({required this.code, required this.name});

  final String code;
  final String name;
}

class AssessmentDraft {
  const AssessmentDraft({required this.id, required this.siteCode});

  final String id;
  final String siteCode;
}

class AssessmentRecord {
  const AssessmentRecord({
    required this.id,
    required this.siteCode,
    required this.submittedAt,
  });

  final String id;
  final String siteCode;
  final DateTime submittedAt;
}
