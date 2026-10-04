import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/icons/water_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';

/// Reached from the Check tab with no site context yet: pick a nearby
/// stream, or add a new user-generated site, before the question flow
/// starts.
class CheckSitePickerScreen extends StatefulWidget {
  const CheckSitePickerScreen({super.key});

  @override
  State<CheckSitePickerScreen> createState() => _CheckSitePickerScreenState();
}

class _CheckSitePickerScreenState extends State<CheckSitePickerScreen> {
  Future<List<StreamSite>>? _sitesFuture;
  bool _addingSite = false;
  final TextEditingController _nameController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _locating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sitesFuture ??= RepositoryScope.of(context).repositories.sites.nearbySites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final strings = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) showFriendlyErrorSnackBar(context, strings.checkLocationUnavailable);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      if (mounted) showFriendlyErrorSnackBar(context, strings.checkLocationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _createSite() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _latitude == null || _longitude == null) return;
    final site = await RepositoryScope.of(context).repositories.sites.createSite(
      name: name,
      latitude: _latitude!,
      longitude: _longitude!,
    );
    if (!mounted) return;
    context.push(AppRoutes.checkAssess, extra: site);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.checkPickSiteTitle)),
      body: SafeArea(
        child: FutureBuilder<List<StreamSite>>(
          future: _sitesFuture ?? Future<List<StreamSite>>.value(const <StreamSite>[]),
          builder: (context, snapshot) {
            final sites = snapshot.data ?? const <StreamSite>[];
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: <Widget>[
                Text(strings.checkPickSiteBody, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (sites.isEmpty)
                  Text(strings.checkNoSitesBody, style: Theme.of(context).textTheme.bodyMedium)
                else ...<Widget>[
                  Text(strings.checkNearbySitesTitle, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  for (final site in sites)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          onTap: () => context.push(AppRoutes.checkAssess, extra: site),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                const WaterIconWidget(
                                  WaterIcon.rippleDrop,
                                  color: AppColors.deepWater,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    site.name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                const PhosphorIcon(PhosphorIconsRegular.caretRight),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (!_addingSite)
                  AquaButton(
                    label: strings.checkAddNewSiteAction,
                    variant: AquaButtonVariant.secondary,
                    leading: const Icon(PhosphorIconsRegular.plus),
                    onPressed: () => setState(() => _addingSite = true),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: strings.checkNewSiteNameLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AquaButton(
                        label: _latitude == null
                            ? strings.checkNewSiteUseLocationAction
                            : strings.checkNewSiteLocationCaptured,
                        variant: AquaButtonVariant.secondary,
                        loading: _locating,
                        leading: const Icon(PhosphorIconsRegular.mapPin),
                        onPressed: _useMyLocation,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AquaButton(
                        label: strings.checkNewSiteCreateAction,
                        onPressed: _createSite,
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
