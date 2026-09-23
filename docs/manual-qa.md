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
