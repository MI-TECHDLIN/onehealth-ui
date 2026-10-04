import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../../core/settings/app_preferences.dart';
import 'assessment_repository.dart';
import 'assessment_content_source.dart';
import 'auth_repository.dart';
import 'live_api_client.dart';
import 'reference_repository.dart';
import 'site_repository.dart';
import 'token_store.dart';

/// Repositories for one isolated data mode.
///
class RepositoryBundle {
  const RepositoryBundle({
    required this.auth,
    required this.sites,
    required this.references,
    required this.assessments,
  });

  factory RepositoryBundle.demo({AppPreferences? preferences}) {
    final content = AssessmentContentSource();
    final assessments = LiveAssessmentRepository(
      api: api,
      auth: auth,
      preferences: preferences,
      contentSource: content,
    );
    unawaited(assessments.retryQueued());
    Connectivity().onConnectivityChanged.listen(
      (connections) {
        if (connections.any((value) => value != ConnectivityResult.none)) {
          unawaited(assessments.retryQueued());
        }
      },
      // Platform channels are absent in widget tests; retries still run on
      // app start and through the explicit Retry action there.
      onError: (_) {},
    );
    return RepositoryBundle(
      auth: DemoAuthRepository(),
      sites: DemoSiteRepository(),
      references: DemoReferenceRepository(contentSource: content),
      assessments: DemoAssessmentRepository(
        preferences: preferences,
        contentSource: content,
      ),
    );
  }

  factory RepositoryBundle.live({
    required AppPreferences preferences,
    http.Client? client,
    TokenStore? tokenStore,
    Uri? baseUri,
  }) {
    final network = client ?? http.Client();
    final tokens = tokenStore ?? SecureTokenStore();
    final auth = LiveAuthRepository(
      client: network,
      tokenStore: tokens,
      baseUri: baseUri,
    );
    final api = LiveApiClient(
      client: network,
      tokenStore: tokens,
      baseUri: baseUri ?? LiveApiClient.productionBaseUri,
      onUnauthorized: auth.invalidateSession,
    );
    final content = AssessmentContentSource();
    return RepositoryBundle(
      auth: auth,
      sites: LiveSiteRepository(api: api),
      references: LiveReferenceRepository(api: api),
      assessments: assessments,
    );
  }

  final AuthRepository auth;
  final SiteRepository sites;
  final ReferenceRepository references;
  final AssessmentRepository assessments;
}
