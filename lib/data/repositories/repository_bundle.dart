import 'assessment_repository.dart';
import 'auth_repository.dart';
import 'reference_repository.dart';
import 'site_repository.dart';

/// Repositories for one isolated data mode.
///
/// Only the local Demo bundle exists in this foundation. A later integration
/// supplies a separate Live bundle; no foundation implementation performs a
/// network request.
class RepositoryBundle {
  const RepositoryBundle({
    required this.auth,
    required this.sites,
    required this.references,
    required this.assessments,
  });

  factory RepositoryBundle.demo() => RepositoryBundle(
    auth: DemoAuthRepository(),
    sites: DemoSiteRepository(),
    references: DemoReferenceRepository(),
    assessments: DemoAssessmentRepository(),
  );

  final AuthRepository auth;
  final SiteRepository sites;
  final ReferenceRepository references;
  final AssessmentRepository assessments;
}
