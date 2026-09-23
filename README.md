# OneAquaHealth UI

Flutter application for the OneAquaHealth citizen-science experience.

## Design-system foundation

- `lib/core/theme/tokens.dart` is the single source of truth for color,
  typography, spacing, radii, and motion.
- `lib/core/theme/app_theme.dart` maps those tokens into light and dark Material
  themes.
- `lib/core/mascot/aqua_mascot.dart` contains the lightweight, code-drawn water
  companion and its smoothly interpolated mood states.

In a debug build, use the "Review all moods" button on the foundation screen or
navigate to `/debug/mascot` to review and interact with every mascot mood. The
debug route is not registered in release builds.

## Validation

```sh
flutter analyze
flutter test
```
