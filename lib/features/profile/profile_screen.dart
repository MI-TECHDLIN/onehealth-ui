import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../core/profile/avatar_catalog.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    final avatarId = settings.avatarId ?? AvatarCatalog.autoAssignedId;
    final auth = RepositoryScope.of(context).repositories.auth;
    return Scaffold(
      appBar: AppBar(title: Text(strings.profileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            Center(
              child: Container(
                width: 132,
                height: 132,
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.waterMist,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    AvatarCatalog.assetFor(avatarId),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => context.go('${AppRoutes.avatar}?change=true'),
                icon: const Icon(Icons.face_retouching_natural_rounded),
                label: Text(strings.authAvatarChangeAction),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FutureBuilder<AuthUser?>(
              future: auth.currentUser(),
              builder: (context, snapshot) => snapshot.data == null
                  ? const SizedBox.shrink()
                  : ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(
                        strings.authSignedInAs(snapshot.data!.username),
                      ),
                      subtitle: snapshot.data!.email == null
                          ? null
                          : Text(snapshot.data!.email!),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (!context.mounted) return;
                context.go(
                  settings.mode.isLive ? AppRoutes.signIn : AppRoutes.home,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(strings.authSignOutAction),
            ),
          ],
        ),
      ),
    );
  }
}
