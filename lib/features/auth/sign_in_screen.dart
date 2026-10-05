import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/mode/app_mode.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../data/repositories/api_failure.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.authRepository,
    this.onSignedIn,
  });

  final AuthRepository? authRepository;
  final VoidCallback? onSignedIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: AquaMascot(
                          mood: _submitting
                              ? MascotMood.thinking
                              : _errorMessage == null
                              ? MascotMood.guiding
                              : MascotMood.concerned,
                          size: 132,
                          pauseAnimations: !_submitting,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        strings.authWelcomeBack,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.authSignInBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_submitting) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            strings.authSigningIn,
                            key: const Key('authLoading'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        FriendlyErrorBanner(
                          key: const Key('authErrorBanner'),
                          title: strings.authErrorTitle,
                          message: _errorMessage!,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        key: const Key('authUsernameField'),
                        controller: _usernameController,
                        enabled: !_submitting,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: InputDecoration(
                          labelText: strings.authUsernameLabel,
                          prefixIcon: const Icon(PhosphorIconsRegular.user),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? strings.authRequiredField
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('authPasswordField'),
                        controller: _passwordController,
                        enabled: !_submitting,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[AutofillHints.password],
                        onFieldSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          labelText: strings.authPasswordLabel,
                          prefixIcon: const Icon(PhosphorIconsRegular.lockSimple),
                          suffixIcon: IconButton(
                            key: const Key('authPasswordVisibility'),
                            tooltip: _obscurePassword
                                ? strings.authShowPassword
                                : strings.authHidePassword,
                            onPressed: _submitting
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? PhosphorIconsRegular.eye
                                  : PhosphorIconsRegular.eyeSlash,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? strings.authRequiredField
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('authSubmitButton'),
                        onPressed: _submitting ? null : _signIn,
                        child: Text(strings.authSignInAction),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextButton(
                        onPressed: _submitting ? null : _useDemo,
                        child: Text(strings.authUseDemoAction),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_submitting || _formKey.currentState?.validate() != true) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final auth =
          widget.authRepository ?? RepositoryScope.of(context).repositories.auth;
      await auth.signIn(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      if (widget.onSignedIn != null) {
        widget.onSignedIn!();
      } else {
        final settings = AppSettingsScope.of(context);
        context.go(
          settings.hasCompletedAvatarSetup
              ? AppRoutes.home
              : AppRoutes.avatar,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = FriendlyError.fromFailure(
          statusCode: error is ApiFailure ? error.statusCode : null,
          error: error is ApiFailure ? error.cause : error,
          isSignIn: true,
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _useDemo() async {
    final settings = AppSettingsScope.of(context);
    await settings.setMode(AppMode.demo);
    if (!mounted) return;
    context.go(
      settings.hasCompletedAvatarSetup ? AppRoutes.home : AppRoutes.avatar,
    );
  }
}
