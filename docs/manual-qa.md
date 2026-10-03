# Manual QA checklist

This is the manual verification checklist for the design system, animated water mascot, and friendly error messages.

Setup: `git checkout staging && git pull`, `flutter pub get`, `flutter run` (debug build, needed for the mascot gallery).

Design system and water mascot:
1. Tap "Review all moods" on the home screen or open `/debug/mascot` - the mascot gallery opens.
2. Tap each mood: calm, ready to guide, thinking, celebrating, concerned - each looks distinct and fits its mood.
3. Switch moods rapidly - smooth blend, no jumps or flicker, mouth changes smoothly.
4. Select celebrating - the bounce may overshoot slightly but never clips at the edges.
5. Leave it on calm for about 30 seconds - gentle idle motion, no drift or jitter.
6. Toggle the phone's light/dark mode - all text, colors and the mascot stay readable in both.
7. Turn on reduce motion (Android "Remove animations" / iOS "Reduce Motion") - the mascot holds still or nearly still and mood changes snap.
8. Run a release build (`flutter run --release`) - no "Review all moods" button and `/debug/mascot` does not open.
9. Small phone, large phone, and large accessibility text size - nothing overflows or gets cut off.

Friendly error messages:
10. Sign in with a wrong password - "That email or password didn't match…", not a session-timeout message.
11. Let the session expire, then act - "Your session timed out — log back in to keep going." with no claim that answers are saved.
12. Airplane mode, then load or save something - "No connection right now. Check your internet and try again."
13. Very slow or stalled network - the same no-connection message, not a generic error.
14. Trigger any other server error - a plain friendly message, never raw status codes, "DioException", JSON, or stack traces.
15. The error snackbar - Retry is easy to read on the pink background and tapping it actually retries.

Items 10-15 have not yet been verified live.

Foundation shell, localization, and modes:
16. Launch after clearing app data - the app starts in Demo mode and the yellow
    Demo badge remains visible across all five main destinations.
17. Use Home, Streams, Check, Impact, and You - each route opens, the selected
    destination uses a filled icon, and Check stays raised at the center.
18. Tap the mode badge, toggle Live, and confirm - the badge turns green and
    shows Live; canceling the confirmation leaves the current mode unchanged.
19. Restart after selecting Live and a different language - both choices are
    restored. Switching back to Demo must not expose Live drafts or history.
20. Select Arabic - layout direction, reading order, and directional icons use
    RTL; Noto Sans Arabic is used and untranslated strings fall back to English.
21. Review all 18 languages at 200% text scale - no clipped navigation labels,
    dialogs, settings rows, or bottom-sheet actions.
22. Turn on Android Remove animations - route changes use a short dissolve with
    no horizontal travel; normal mode uses the horizontal shared-axis motion.
23. In a release build, the Ripple gallery route and Settings row are absent.

Items 16-23 require on-device verification.
