import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/motion/app_page_transitions.dart';
import '../core/motion/motion_preferences.dart';
import '../core/settings/app_settings_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/repository_models.dart';
import '../debug/mascot_gallery_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/check/assessment_review_screen.dart';
import '../features/check/assessment_celebration_screen.dart';
import '../features/check/assessment_shell.dart';
import '../features/check/check_site_picker_screen.dart';
import '../features/check/photo_capture_screen.dart';
import '../features/home/home_map_screen.dart';
import '../features/home/site_detail_screen.dart';
import '../features/home/stream_map_view.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/avatar_picker_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/placeholder_screen.dart';
import '../features/streams/my_streams_screen.dart';
import '../l10n/generated/app_localizations.dart';

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String avatar = '/choose-avatar';
  static const String home = '/home';
  static const String streams = '/streams';
  static const String check = '/check';
  static const String checkAssess = '/check/assess';
  static const String checkReview = '/check/review';
  static const String checkPhotos = '/check/photos';
  static const String checkCelebration = '/check/celebration';
  static const String impact = '/impact';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String siteDetail = '/site';
}

GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  AppSettingsController? settings,
  AuthRepository? liveAuth,
  // Overrides the map home's native MapLibre view. Tests pass a stand-in
  // widget here instead of standing up a real platform view; production
  // leaves this null and gets the real map.
  StreamMapViewBuilder? homeMapViewBuilder,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: settings == null
      ? null
      : Listenable.merge(<Listenable>[
          settings,
          if (liveAuth is Listenable) liveAuth,
        ]),
  redirect: settings == null || liveAuth == null
      ? null
      : (context, state) async {
          if (!settings.mode.isLive ||
              state.matchedLocation == AppRoutes.onboarding) {
            return null;
          }
          final isSignedIn = await liveAuth.currentUser() != null;
          final atSignIn = state.matchedLocation == AppRoutes.signIn;
          if (!isSignedIn && !atSignIn) return AppRoutes.signIn;
          if (isSignedIn && atSignIn) {
            return settings.hasCompletedAvatarSetup
                ? AppRoutes.home
                : AppRoutes.avatar;
          }
          return null;
        },
  errorPageBuilder: (context, state) => _page(
    context: context,
    state: state,
    child: Scaffold(
      body: PlaceholderScreen(
        title: AppLocalizations.of(context).pageUnavailableTitle,
        body: AppLocalizations.of(context).pageUnavailableBody,
        icon: PhosphorIconsRegular.signpost,
      ),
    ),
  ),
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: OnboardingScreen(
          isReplay: state.uri.queryParameters['replay'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: const SignInScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.avatar,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: AvatarPickerScreen(
          returnToProfile: state.uri.queryParameters['change'] == 'true',
        ),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(
        currentPath: state.uri.path,
        child: child,
      ),
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => _page(
            context: context,
            state: state,
            child: HomeMapScreen(
              mapViewBuilder: homeMapViewBuilder ?? buildDefaultStreamMapView,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.streams,
          pageBuilder: (context, state) => _page(
            context: context,
            state: state,
            child: const MyStreamsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.check,
          pageBuilder: (context, state) => _page(
            context: context,
            state: state,
            child: const CheckSitePickerScreen(),
          ),
        ),
        _placeholderRoute(
          path: AppRoutes.impact,
          icon: PhosphorIconsRegular.chartLineUp,
          title: (strings) => strings.impactTitle,
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => _page(
            context: context,
            state: state,
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '${AppRoutes.siteDetail}/:code',
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: SiteDetailScreen(
          code: state.pathParameters['code']!,
          site: state.extra is StreamSite ? state.extra! as StreamSite : null,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.checkAssess,
      redirect: (context, state) =>
          state.extra is StreamSite ? null : AppRoutes.check,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: AssessmentShell(
          site: state.extra! as StreamSite,
          initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.checkPhotos,
      redirect: (context, state) =>
          state.extra is AssessmentDraft ? null : AppRoutes.home,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: PhotoCaptureScreen(draft: state.extra! as AssessmentDraft),
      ),
    ),
    GoRoute(
      path: AppRoutes.checkReview,
      redirect: (context, state) =>
          state.extra is AssessmentDraft ? null : AppRoutes.home,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: AssessmentReviewScreen(draft: state.extra! as AssessmentDraft),
      ),
    ),
    GoRoute(
      path: AppRoutes.checkCelebration,
      redirect: (context, state) =>
          state.extra is AssessmentCelebrationData ? null : AppRoutes.home,
      pageBuilder: (context, state) => _page(
        context: context,
        state: state,
        child: AssessmentCelebrationScreen(
          data: state.extra! as AssessmentCelebrationData,
        ),
      ),
    ),
    if (kDebugMode)
      GoRoute(
        path: MascotGalleryScreen.routeName,
        pageBuilder: (context, state) => _page(
          context: context,
          state: state,
          child: const MascotGalleryScreen(),
        ),
      ),
  ],
);

GoRoute _placeholderRoute({
  required String path,
  required IconData icon,
  required String Function(AppLocalizations strings) title,
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) => _page(
    context: context,
    state: state,
    child: PlaceholderScreen(
      title: title(AppLocalizations.of(context)),
      icon: icon,
    ),
  ),
);

CustomTransitionPage<void> _page({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  transitionDuration: MotionPreferences.pageDurationOf(context),
  reverseTransitionDuration: MotionPreferences.pageDurationOf(context),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      AppRouteTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      ),
  child: child,
);
