import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/data/repositories/api_failure.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/live_api_client.dart';
import 'package:onehealth_ui/data/repositories/reference_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/site_repository.dart';
import 'package:onehealth_ui/data/repositories/token_store.dart';

void main() {
  final testBase = Uri.parse('https://example.invalid/');
  final now = DateTime.utc(2026, 10, 4);

  group('LiveAuthRepository', () {
    test('posts credentials, stores raw JWT, and reads profile claims', () async {
      final token = _jwt(<String, Object?>{
        'username': 'river-user',
        'name': 'River User',
        'email': 'river@example.invalid',
        'scope': <String>['UPLOAD_FILES'],
        'exp': 2100000000,
      });
      final store = MemoryTokenStore();
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), <String, Object?>{
          'username': 'river-user',
          'password': 'test-password',
        });
        return http.Response(token, 200, headers: <String, String>{
          'content-type': 'text/plain;charset=UTF-8',
        });
      });
      final repository = LiveAuthRepository(
        client: client,
        tokenStore: store,
        baseUri: testBase,
        now: () => now,
      );

      final signedIn = await repository.signIn(
        username: 'river-user',
        password: 'test-password',
      );

      expect(store.value, token);
      expect(signedIn.displayName, 'River User');
      expect(signedIn.email, 'river@example.invalid');
      expect((await repository.currentUser())?.username, 'river-user');
    });

    test('expired tokens are cleared without a network call', () async {
      final store = MemoryTokenStore(
        _jwt(<String, Object?>{'username': 'old-user', 'exp': 1}),
      );
      final repository = LiveAuthRepository(
        client: MockClient((_) => throw StateError('must not call network')),
        tokenStore: store,
        baseUri: testBase,
        now: () => now,
      );

      expect(await repository.currentUser(), isNull);
      expect(store.value, isNull);
    });

    test('401 from authenticated API clears the session', () async {
      final store = MemoryTokenStore(
        _jwt(<String, Object?>{'username': 'river-user', 'exp': 2100000000}),
      );
      var invalidated = false;
      final api = LiveApiClient(
        client: MockClient((_) async => http.Response('', 401)),
        tokenStore: store,
        baseUri: testBase,
        onUnauthorized: () async => invalidated = true,
      );

      await expectLater(api.get('/api/sites/all'), throwsA(isA<ApiFailure>()));
      expect(store.value, isNull);
      expect(invalidated, isTrue);
    });
  });

  test('reference and site repositories map contract shapes and sort locally', () async {
    final tokenStore = MemoryTokenStore(
      _jwt(<String, Object?>{'username': 'river-user', 'exp': 2100000000}),
    );
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/citizens/channel_forms':
          return http.Response(
            jsonEncode(<Object?>[
              <String, Object?>{'code': 'U', 'name': 'U Shape (B)'},
            ]),
            200,
          );
        case '/api/sites/all':
          return http.Response(
            jsonEncode(<Object?>[
              <String, Object?>{
                'code': 'FAR',
                'name': 'Far Stream',
                'latitude': '41.5',
                'longitude': '-8.5',
                'altitude': 12,
                'city': <String, Object?>{'name': 'Test City'},
              },
            ]),
            200,
          );
        case '/api/sites/user-generated':
          return http.Response(
            jsonEncode(<Object?>[
              <String, Object?>{
                'userSiteCode': 'NEAR',
                'name': 'Near Stream',
                'latitude': '41.001',
                'longitude': '-8.001',
              },
            ]),
            200,
          );
        case '/api/citizens/user-generated-sites/insert':
          expect(jsonDecode(request.body), <String, Object?>{
            'name': 'New Reach',
            'latitude': 41.2,
            'longitude': -8.2,
          });
          return http.Response(jsonEncode('UG-NEW'), 200);
        default:
          fail('Unexpected fake request: ${request.method} ${request.url}');
      }
    });
    final api = LiveApiClient(
      client: client,
      tokenStore: tokenStore,
      baseUri: testBase,
    );

    final references = LiveReferenceRepository(api: api);
    final values = await references.valuesFor('channel_forms');
    expect(values.single.code, 'U');

    final sites = LiveSiteRepository(api: api);
    final nearby = await sites.nearbySites(latitude: 41, longitude: -8);
    expect(nearby.map((site) => site.code), <String>['NEAR', 'FAR']);
    expect(nearby.first.isUserGenerated, isTrue);
    expect(nearby.first.distanceKm, isNotNull);
    final created = await sites.createSite(
      name: 'New Reach',
      latitude: 41.2,
      longitude: -8.2,
    );
    expect(created.code, 'UG-NEW');
  });

  test('submission uploads raw files before payload and history drops other users', () async {
    final calls = <String>[];
    Map<String, dynamic>? submittedPayload;
    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      switch (request.url.path) {
        case '/api/files':
          expect(request.url.queryParameters['filename'], 'upstream.jpg');
          expect(request.bodyBytes, <int>[1, 2, 3]);
          return http.Response(
            jsonEncode(<String, Object?>{'id': 'FILE-1', 'filename': 'upstream.jpg'}),
            200,
          );
        case '/api/citizens/submit':
          submittedPayload = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
          return http.Response('', 200);
        case '/api/citizens/submissions':
          return http.Response(
            jsonEncode(<Object?>[
              _record(id: 'private-other', user: 'someone-else'),
              _record(id: 'mine', user: 'river-user'),
            ]),
            200,
          );
        case '/api/citizens/user-generated-sites/my-submissions':
          return http.Response(
            jsonEncode(<Object?>[
              _record(
                id: 'my-user-site',
                user: 'river-user',
                userGeneratedSite: 'UG-1',
              ),
            ]),
            200,
          );
        default:
          fail('Unexpected fake request: ${request.method} ${request.url}');
      }
    });
    final api = LiveApiClient(
      client: client,
      tokenStore: MemoryTokenStore(
        _jwt(<String, Object?>{'username': 'river-user', 'exp': 2100000000}),
      ),
      baseUri: testBase,
    );
    final repository = LiveAssessmentRepository(
      api: api,
      auth: const _StaticAuthRepository('river-user'),
      preferences: MemoryAppPreferences(),
      now: () => now,
    );
    final draft = AssessmentDraft(
      id: 'draft-1',
      siteCode: 'SITE-1',
      latitude: 41,
      longitude: -8,
      attachments: <AssessmentMediaRole, AssessmentAttachment>{
        AssessmentMediaRole.upstreamPhoto: AssessmentAttachment(
          filename: 'upstream.jpg',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          contentType: 'image/jpeg',
        ),
      },
      channelForm: 'I am not sure',
      waterAbstraction: false,
      vegetationTypeLeft: "I'm not sure",
      overallAssessment: 'GOOD',
      joy: 0,
      serenity: 5,
      anger: 2,
      fear: 3,
    );

    await repository.submit(draft);

    expect(calls.take(2), <String>['PUT /api/files', 'PUT /api/citizens/submit']);
    expect(submittedPayload?['upstreamPhoto'], 'FILE-1');
    expect(submittedPayload?['waterAbstraction'], isFalse);
    expect(submittedPayload?['channelForm'], isNull);
    expect(submittedPayload?['vegetationTypeLeft'], isNull);
    expect(submittedPayload?['joy'], 0);

    final history = await repository.history();
    expect(history.map((record) => record.id), containsAll(<String>['mine', 'my-user-site']));
    expect(history.map((record) => record.id), isNot(contains('private-other')));
  });
}

String _jwt(Map<String, Object?> claims) {
  String encode(Object value) => base64Url
      .encode(utf8.encode(jsonEncode(value)))
      .replaceAll('=', '');
  return '${encode(<String, Object?>{'alg': 'HS256'})}.${encode(claims)}.signature';
}

Map<String, Object?> _record({
  required String id,
  required String user,
  String? userGeneratedSite,
}) => <String, Object?>{
  'id': id,
  'user': user,
  'researchSite': userGeneratedSite == null ? 'SITE-1' : null,
  'userGeneratedSite': userGeneratedSite,
  'createdAt': '2026-10-03T10:00:00Z',
  'latitude': 41,
  'longitude': -8,
  'overallAssessment': 'GOOD',
  'joy': 3,
  'serenity': 3,
  'anger': 0,
  'fear': 0,
};

class _StaticAuthRepository implements AuthRepository {
  const _StaticAuthRepository(this.username);

  final String username;

  @override
  Future<AuthUser?> currentUser() async =>
      AuthUser(username: username, displayName: username);

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}
