import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/motion/motion_preferences.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'gps_proximity_rule.dart';
import 'photo_quality.dart';

typedef AssessmentImagePicker = Future<XFile?> Function(ImageSource source);

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({
    super.key,
    required this.draft,
    this.pickImage,
  });

  final AssessmentDraft draft;
  final AssessmentImagePicker? pickImage;

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  late AssessmentDraft _draft = widget.draft;
  AssessmentMediaRole? _processingRole;
  bool _checkingLocation = false;
  String? _friendlyError;

  static const _roles = <AssessmentMediaRole>[
    AssessmentMediaRole.upstreamPhoto,
    AssessmentMediaRole.downstreamPhoto,
    AssessmentMediaRole.surroundingPhoto,
    AssessmentMediaRole.interestingPhoto,
  ];

  Future<XFile?> _pickImage(ImageSource source) {
    final override = widget.pickImage;
    if (override != null) return override(source);
    return ImagePicker().pickImage(
      source: source,
      requestFullMetadata: false,
    );
  }

  Future<void> _pickGallery(AssessmentMediaRole role) async {
    setState(() {
      _friendlyError = null;
      _processingRole = role;
    });
    try {
      final file = await _pickImage(ImageSource.gallery);
      if (file == null) return;
      final processed = await PhotoProcessor.process(await file.readAsBytes());
      if (!mounted) return;
      if (processed.quality.shouldSuggestRetake) {
        final keep = await _showQualitySuggestion(processed.quality);
        if (!keep || !mounted) return;
      }
      final attachments = Map<AssessmentMediaRole, AssessmentAttachment>.of(
        _draft.attachments,
      );
      attachments[role] = AssessmentAttachment(
        filename: _jpegFilename(file.name, role),
        bytes: processed.bytes,
        contentType: 'image/jpeg',
      );
      final next = _draft.copyWith(attachments: attachments);
      setState(() => _draft = next);
      await RepositoryScope.of(context).repositories.assessments.saveDraft(next);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _friendlyError = FriendlyError.fromFailure(error: error));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _friendlyError = FriendlyError.fromFailure(error: error));
      }
    } finally {
      if (mounted) setState(() => _processingRole = null);
    }
  }

  Future<void> _openCamera(AssessmentMediaRole role) async {
    final reduceMotion = MotionPreferences.reduceMotionOf(context);
    final strings = AppLocalizations.of(context);
    final captured = await showGeneralDialog<_CapturedPhoto>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: reduceMotion ? AppMotion.reduced : AppMotion.page,
      pageBuilder: (context, animation, secondaryAnimation) => _CameraOverlay(
        roleTitle: _roleTitle(strings, role),
        guide: _roleGuide(strings, role),
        pickGallery: () => _pickImage(ImageSource.gallery),
        animation: CurvedAnimation(
          parent: animation,
          curve: AppMotion.pageCurve,
        ),
        reduceMotion: reduceMotion,
      ),
    );
    if (captured == null || !mounted) return;
    await _storePhoto(role, captured.filename, captured.photo);
  }

  Future<void> _storePhoto(
    AssessmentMediaRole role,
    String filename,
    ProcessedPhoto processed,
  ) async {
    final attachments = Map<AssessmentMediaRole, AssessmentAttachment>.of(
      _draft.attachments,
    );
    attachments[role] = AssessmentAttachment(
      filename: _jpegFilename(filename, role),
      bytes: processed.bytes,
      contentType: 'image/jpeg',
    );
    final next = _draft.copyWith(attachments: attachments);
    setState(() => _draft = next);
    await RepositoryScope.of(context).repositories.assessments.saveDraft(next);
  }

  String _jpegFilename(String original, AssessmentMediaRole role) {
    final dot = original.lastIndexOf('.');
    final stem = dot > 0 ? original.substring(0, dot) : role.name;
    return '$stem.jpg';
  }

  Future<bool> _showQualitySuggestion(PhotoQualityResult quality) async {
    final strings = AppLocalizations.of(context);
    final issue = quality.issues.first;
    final reason = switch (issue) {
      PhotoQualityIssue.tooDark => strings.assessPhotoTooDark,
      PhotoQualityIssue.tooBright => strings.assessPhotoTooBright,
      PhotoQualityIssue.blurry => strings.assessPhotoBlurry,
      PhotoQualityIssue.obstructed => strings.assessPhotoObstructed,
    };
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const AquaMascot(
              mood: MascotMood.concerned,
              size: 76,
              pauseAnimations: true,
            ),
            title: Text(strings.assessPhotoQualityTitle),
            content: Text(reason),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.assessPhotoRetakeAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.assessPhotoKeepAction),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _remove(AssessmentMediaRole role) async {
    final attachments = Map<AssessmentMediaRole, AssessmentAttachment>.of(
      _draft.attachments,
    )..remove(role);
    final next = _draft.copyWith(attachments: attachments);
    setState(() => _draft = next);
    await RepositoryScope.of(context).repositories.assessments.saveDraft(next);
  }

  Future<void> _checkLocationAndContinue() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _checkingLocation = true;
      _friendlyError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _offerGpsFallback();
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final result = GpsProximityRule.evaluate(
        siteLatitude: _draft.siteLatitude ?? _draft.latitude,
        siteLongitude: _draft.siteLongitude ?? _draft.longitude,
        observedLatitude: position.latitude,
        observedLongitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
      var confirmed = !result.requiresConfirmation;
      if (result.requiresConfirmation && mounted) {
        confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.assessGpsConfirmTitle),
                content: Text(
                  strings.assessGpsConfirmBody(
                    result.distanceMeters.round(),
                    result.accuracyMeters.round(),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(strings.assessGpsCancelAction),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(strings.assessGpsConfirmAction),
                  ),
                ],
              ),
            ) ??
            false;
      }
      if (!confirmed || !mounted) return;
      final next = _draft.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        gpsAccuracyMeters: position.accuracy,
        gpsDistanceMeters: result.distanceMeters,
        gpsConfirmed: true,
      );
      setState(() => _draft = next);
      await RepositoryScope.of(context).repositories.assessments.saveDraft(next);
      if (mounted) context.go(AppRoutes.checkReview, extra: next);
    } catch (_) {
      if (mounted) await _offerGpsFallback();
    } finally {
      if (mounted) setState(() => _checkingLocation = false);
    }
  }

  Future<void> _offerGpsFallback() async {
    final strings = AppLocalizations.of(context);
    final continueWithout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.assessGpsUnavailableTitle),
            content: Text(strings.assessGpsUnavailableBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.assessQueueRetryAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.assessGpsContinueWithoutAction),
              ),
            ],
          ),
        ) ??
        false;
    if (continueWithout && mounted) {
      final next = _draft.copyWith(gpsConfirmed: true);
      await RepositoryScope.of(context).repositories.assessments.saveDraft(next);
      if (mounted) context.go(AppRoutes.checkReview, extra: next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.assessPhotoTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            Text(strings.assessPhotoBody, style: Theme.of(context).textTheme.bodyLarge),
            if (_friendlyError != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              FriendlyErrorBanner(
                message: _friendlyError!,
                retryLabel: strings.assessPhotoSettingsAction,
                onRetry: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            for (final role in _roles) ...<Widget>[
              _PhotoRoleCard(
                title: _roleTitle(strings, role),
                guide: _roleGuide(strings, role),
                attachment: _draft.attachments[role],
                processing: _processingRole == role,
                onCamera: () => _openCamera(role),
                onGallery: () => _pickGallery(role),
                onRemove: () => _remove(role),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AquaButton(
              label: _checkingLocation
                  ? strings.assessGpsChecking
                  : strings.assessPhotoContinueAction,
              loading: _checkingLocation,
              onPressed: _processingRole == null ? _checkLocationAndContinue : null,
            ),
          ],
        ),
      ),
    );
  }

  String _roleTitle(AppLocalizations strings, AssessmentMediaRole role) =>
      switch (role) {
        AssessmentMediaRole.upstreamPhoto => strings.assessPhotoUpstream,
        AssessmentMediaRole.downstreamPhoto => strings.assessPhotoDownstream,
        AssessmentMediaRole.surroundingPhoto => strings.assessPhotoSurroundings,
        AssessmentMediaRole.interestingPhoto => strings.assessPhotoBiodiversity,
        AssessmentMediaRole.video => '',
      };

  String _roleGuide(AppLocalizations strings, AssessmentMediaRole role) =>
      switch (role) {
        AssessmentMediaRole.upstreamPhoto => strings.assessPhotoUpstreamGuide,
        AssessmentMediaRole.downstreamPhoto => strings.assessPhotoDownstreamGuide,
        AssessmentMediaRole.surroundingPhoto => strings.assessPhotoSurroundingsGuide,
        AssessmentMediaRole.interestingPhoto => strings.assessPhotoBiodiversityGuide,
        AssessmentMediaRole.video => '',
      };
}

class _PhotoRoleCard extends StatelessWidget {
  const _PhotoRoleCard({
    required this.title,
    required this.guide,
    required this.attachment,
    required this.processing,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final String title;
  final String guide;
  final AssessmentAttachment? attachment;
  final bool processing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final image = attachment;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              Text(strings.assessOptionalLabel, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(guide),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: AppSizes.photoAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (image == null)
                    ColoredBox(
                      color: AppColors.navy,
                      child: Center(
                        child: Icon(
                          PhosphorIconsRegular.camera,
                          size: AppSpacing.xxl,
                          color: AppColors.white.withValues(
                            alpha: AppOpacity.photoPlaceholder,
                          ),
                        ),
                      ),
                    )
                  else
                    Image.memory(image.bytes, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.white, width: AppStrokes.selected),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                  ),
                  if (processing)
                    ColoredBox(
                      color: AppColors.navy.withValues(alpha: AppOpacity.scrim),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const CircularProgressIndicator(color: AppColors.white),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              strings.assessPhotoProcessing,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: AquaButton(
                  label: image == null
                      ? strings.assessPhotoCameraAction
                      : strings.assessPhotoRetakeAction,
                  variant: AquaButtonVariant.secondary,
                  leading: const Icon(PhosphorIconsRegular.camera),
                  onPressed: processing ? null : onCamera,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AquaButton(
                  label: strings.assessPhotoGalleryAction,
                  variant: AquaButtonVariant.secondary,
                  leading: const Icon(PhosphorIconsRegular.image),
                  onPressed: processing ? null : onGallery,
                ),
              ),
            ],
          ),
          if (image != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: processing ? null : onRemove,
                icon: const Icon(PhosphorIconsRegular.trash),
                label: Text(strings.assessPhotoRemoveAction),
              ),
            ),
        ],
      ),
    );
  }
}

class _CapturedPhoto {
  const _CapturedPhoto({required this.filename, required this.photo});

  final String filename;
  final ProcessedPhoto photo;
}

class _CameraOverlay extends StatefulWidget {
  const _CameraOverlay({
    required this.roleTitle,
    required this.guide,
    required this.pickGallery,
    required this.animation,
    required this.reduceMotion,
  });

  final String roleTitle;
  final String guide;
  final Future<XFile?> Function() pickGallery;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  State<_CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<_CameraOverlay>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  _CapturedPhoto? _captured;
  bool _busy = true;
  bool _showOptions = false;
  String? _friendlyError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      unawaited(_disposeController());
    } else if (state == AppLifecycleState.resumed && _captured == null) {
      unawaited(_initialize(cameraIndex: _cameraIndex));
    }
  }

  Future<void> _initialize({int cameraIndex = 0}) async {
    if (mounted) {
      setState(() {
        _busy = true;
        _friendlyError = null;
      });
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw CameraException('noCamera', '');
      _cameraIndex = cameraIndex.clamp(0, _cameras.length - 1).toInt();
      final next = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      await _disposeController();
      setState(() {
        _controller = next;
        _busy = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _friendlyError = FriendlyError.fromFailure(error: error);
        });
      }
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;
    setState(() {
      _busy = true;
      _showOptions = false;
    });
    try {
      final file = await controller.takePicture();
      final processed = await PhotoProcessor.process(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _captured = _CapturedPhoto(filename: file.name, photo: processed);
        _busy = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _friendlyError = FriendlyError.fromFailure(error: error);
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _busy = true;
      _showOptions = false;
    });
    try {
      final file = await widget.pickGallery();
      if (file == null) return;
      final processed = await PhotoProcessor.process(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _captured = _CapturedPhoto(filename: file.name, photo: processed);
        _busy = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _friendlyError = FriendlyError.fromFailure(error: error);
        });
      }
    } finally {
      if (mounted && _captured == null) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      // Some cameras do not expose a flash. The option remains harmless.
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _busy) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    setState(() => _showOptions = false);
    await _disposeController();
    await _initialize(cameraIndex: next);
  }

  void _retake() {
    setState(() {
      _captured = null;
      _friendlyError = null;
    });
    if (_controller == null) unawaited(_initialize(cameraIndex: _cameraIndex));
  }

  String? _qualityReason(AppLocalizations strings) {
    final quality = _captured?.photo.quality;
    if (quality == null || quality.issues.isEmpty) return null;
    return switch (quality.issues.first) {
      PhotoQualityIssue.tooDark => strings.assessPhotoTooDark,
      PhotoQualityIssue.tooBright => strings.assessPhotoTooBright,
      PhotoQualityIssue.blurry => strings.assessPhotoBlurry,
      PhotoQualityIssue.obstructed => strings.assessPhotoObstructed,
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FadeTransition(
              opacity: widget.animation,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppSizes.cameraBackdropBlur,
                  sigmaY: AppSizes.cameraBackdropBlur,
                ),
                child: ColoredBox(
                  color: AppColors.navy.withValues(alpha: AppOpacity.scrim),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: widget.reduceMotion
                ? FadeTransition(opacity: widget.animation, child: _buildPanel(context))
                : SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(widget.animation),
                    child: _buildPanel(context),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final captured = _captured;
    final qualityReason = _qualityReason(strings);
    return FractionallySizedBox(
              heightFactor: AppSizes.cameraPanelHeightFactor,
              widthFactor: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.xl),
                ),
                child: Material(
                  color: AppColors.navy,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (captured != null)
                        Image.memory(captured.photo.bytes, fit: BoxFit.cover)
                      else if (_controller?.value.isInitialized ?? false)
                        CameraPreview(_controller!)
                      else
                        const ColoredBox(color: AppColors.navy),
                      ColoredBox(
                        color: AppColors.navy.withValues(
                          alpha: AppOpacity.cameraPreviewScrim,
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        child: Column(
                          children: <Widget>[
                            Text(
                              widget.roleTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              widget.guide,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSizes.cameraFrameTopInset,
                              AppSpacing.lg,
                              AppSizes.cameraFrameBottomInset,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.white,
                                  width: AppStrokes.selected,
                                ),
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_friendlyError != null)
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSizes.cameraMessageBottomInset,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FriendlyErrorBanner(
                                message: _friendlyError!,
                                retryLabel: strings.assessPhotoSettingsAction,
                                onRetry: () async {
                                  await Geolocator.openAppSettings();
                                },
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AquaButton(
                                label: strings.assessPhotoGalleryAction,
                                variant: AquaButtonVariant.secondary,
                                leading: const Icon(PhosphorIconsRegular.image),
                                onPressed: _pickFromGallery,
                              ),
                            ],
                          ),
                        ),
                      if (qualityReason != null)
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSizes.cameraMessageBottomInset,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: Row(
                              children: <Widget>[
                                const AquaMascot(
                                  mood: MascotMood.concerned,
                                  size: 54,
                                  pauseAnimations: true,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        strings.assessPhotoQualityTitle,
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                      Text(qualityReason),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_showOptions && captured == null)
                        Positioned(
                          right: AppSpacing.md,
                          bottom: AppSizes.cameraOptionsBottomInset,
                          child: _CameraOptions(
                            onGallery: _pickFromGallery,
                            onFlash: _toggleFlash,
                            onSwitch: _switchCamera,
                          ),
                        ),
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.lg,
                        child: captured == null
                            ? _LiveCameraControls(
                                busy: _busy,
                                onClose: () => Navigator.of(context).pop(),
                                onShutter: _capture,
                                onMore: () => setState(
                                  () => _showOptions = !_showOptions,
                                ),
                              )
                            : Row(
                                children: <Widget>[
                                  Expanded(
                                    child: AquaButton(
                                      label: strings.assessPhotoRetakeAction,
                                      variant: AquaButtonVariant.secondary,
                                      onPressed: _retake,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: AquaButton(
                                      label: strings.assessPhotoUseAction,
                                      onPressed: () => Navigator.of(context).pop(captured),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (_busy)
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.white),
                        ),
                    ],
                  ),
                ),
              ),
            );
  }
}

class _LiveCameraControls extends StatelessWidget {
  const _LiveCameraControls({
    required this.busy,
    required this.onClose,
    required this.onShutter,
    required this.onMore,
  });

  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onShutter;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _RoundCameraButton(
          tooltip: strings.assessPhotoCloseCamera,
          icon: PhosphorIconsRegular.x,
          onPressed: onClose,
        ),
        Semantics(
          button: true,
          label: strings.assessPhotoCameraAction,
          child: GestureDetector(
            onTap: busy ? null : onShutter,
            child: Container(
              width: AppSizes.cameraShutter,
              height: AppSizes.cameraShutter,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: AppStrokes.focus),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        _RoundCameraButton(
          tooltip: strings.assessPhotoMoreOptions,
          icon: PhosphorIconsRegular.dotsThreeVertical,
          onPressed: onMore,
        ),
      ],
    );
  }
}

class _RoundCameraButton extends StatelessWidget {
  const _RoundCameraButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.navy.withValues(alpha: AppOpacity.cameraControl),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.white,
      icon: Icon(icon),
    ),
  );
}

class _CameraOptions extends StatelessWidget {
  const _CameraOptions({
    required this.onGallery,
    required this.onFlash,
    required this.onSwitch,
  });

  final VoidCallback onGallery;
  final VoidCallback onFlash;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: AppColors.navy.withValues(alpha: AppOpacity.cameraMenu),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: strings.assessPhotoGalleryAction,
            onPressed: onGallery,
            color: AppColors.white,
            icon: const Icon(PhosphorIconsRegular.image),
          ),
          IconButton(
            tooltip: strings.assessPhotoFlashAction,
            onPressed: onFlash,
            color: AppColors.white,
            icon: const Icon(PhosphorIconsRegular.lightning),
          ),
          IconButton(
            tooltip: strings.assessPhotoSwitchCameraAction,
            onPressed: onSwitch,
            color: AppColors.white,
            icon: const Icon(PhosphorIconsRegular.cameraRotate),
          ),
        ],
      ),
    );
  }
}
