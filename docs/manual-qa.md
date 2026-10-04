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
10. In the gallery, play Wave, Point, Nod, Jump + splash, Swim in, and Talk - each action is distinct; Point aims up-right and Talk changes smoothly through all four mouth cues.
11. Turn on reduced motion and replay every gesture - Ripple holds a meaningful final pose and the celebration/badge animations show their completed frame without moving.
12. Press and hold primary and secondary buttons - they move down 4 dp and their tactile base compresses; loading and disabled examples cannot be tapped.
13. Review progress, pager, chips, picture choices, “I'm not sure,” loading, celebration, and badge examples at 200% text and in RTL - labels remain readable and selected state is never color-only.
14. Review locked, unlocked, new, and unlock-reveal badges - locked criteria remain readable, New is labeled, and the reveal paints real particles at mid-animation.

Friendly error messages:
15. Sign in with a wrong password - "That email or password didn't match…", not a session-timeout message.
16. Let the session expire, then act - "Your session timed out — log back in to keep going." with no claim that answers are saved.
17. Airplane mode, then load or save something - "No connection right now. Check your internet and try again."
18. Very slow or stalled network - the same no-connection message, not a generic error.
19. Trigger any other server error - a plain friendly message, never raw status codes, "DioException", JSON, or stack traces.
20. The error banner and snackbar show concerned Ripple; Retry is easy to read on the pink background and tapping it actually retries.

Items 10-20 have not yet been verified live.

Foundation shell, localization, and modes:
21. Launch after clearing app data - the app starts in Demo mode and the yellow
    Demo badge remains visible across all five main destinations.
22. Use Home, Streams, Check, Impact, and You - each route opens, the selected
    destination uses a filled icon, and Check stays raised at the center.
23. Tap the mode badge, toggle Live, and confirm - the badge turns green and
    shows Live; canceling the confirmation leaves the current mode unchanged.
24. Restart after selecting Live and a different language - both choices are
    restored. Switching back to Demo must not expose Live drafts or history.
25. Select Arabic - layout direction, reading order, and directional icons use
    RTL; Noto Sans Arabic is used and untranslated strings fall back to English.
26. Review all 18 languages at 200% text scale - no clipped navigation labels,
    dialogs, settings rows, or bottom-sheet actions.
27. Turn on Android Remove animations - route changes use a short dissolve with
    no horizontal travel; normal mode uses the horizontal shared-axis motion.
28. In a release build, the Ripple gallery route and Settings row are absent.

Items 21-28 require on-device verification.

Onboarding and read-aloud narration:
29. Clear app data and launch - the five-screen onboarding story opens before
    Home; Ripple plays a distinct gesture on each screen (swim in, wave,
    point, nod, jump) and the final screen shows both "Get started" and
    "Look around first".
30. On each screen, tap Listen - narration plays once (never autoplays),
    words highlight in reading order with both a fill and an underline (not
    color alone), and Ripple's mouth moves in sync. Tap Pause mid-sentence,
    then Listen again - playback resumes from where it paused, not the start.
31. Let narration finish - the control switches to Replay and tapping it
    restarts from the first word.
32. Start narration, then background the app or receive a call - playback
    pauses for the interruption and does not talk over it.
33. Turn off "Read-aloud narration" in Settings - the Listen control
    disappears from every onboarding screen; turn it back on - it returns.
34. Turn on reduce motion and replay the story - page transitions become an
    instant cut, Ripple's gestures hold a settled pose, and Listen/word
    highlighting still work normally.
35. On the data-journey screen, confirm the field-safety reminder (stay on
    the bank, watch for slippery banks, adults with children, skip in bad
    weather) is visible and included in the narration.
36. Tap "Get started" - onboarding is marked complete and the app hands off
    to `/sign-in`; relaunch - onboarding does not show again. Tap
    "Look around first" instead (after clearing app data again) - the app
    enters Demo avatar setup, then Home after choosing or skipping an avatar.
37. Open Settings -> "Replay onboarding" - the story reopens; its "Get
    started"/"Look around first" return to Settings instead of re-routing
    into sign-in or resetting the mode.
38. Open Settings -> Credits - the Piper "alba" voice and its CC BY 4.0
    license are listed.

Items 29-38 require on-device verification.

Authentication, Live data, and avatars:
39. Switch to Live while signed out - `/sign-in` opens and no Live site,
    reference, history, file, or submission request occurs before sign-in.
40. Enter a wrong username/password - the inline concerned-Ripple banner says
    the details did not match; it never says the session expired or shows a
    status code/server response.
41. During a slow sign-in - controls are disabled, thinking Ripple appears, and
    “Signing you in…” is announced. Toggle password visibility before retrying.
42. Complete a first successful sign-in - Choose your avatar appears once with
    a three-column grid of 12 centred, forward-facing, happy portraits; only the
    selected portrait is in colour and has a check. Confirm the set varies skin
    tone, hair, hijab, turban, facial hair, glasses, and clothing without any
    sad, angry, worried, or surprised expressions.
43. Choose “Do this later” after clearing app data - an avatar is assigned and
    persists after restart. Change it later from You/Profile and confirm the new
    choice persists. Open Settings -> Credits - Avataaars is attributed to
    Pablo Stanley, remixed by DiceBear, and marked free for personal and
    commercial use; Open Peeps is no longer listed.
44. In Live mode, load sites with location available - curated and
    user-generated sites are combined and ordered nearest-first. Create a test
    site only with an owner-approved test account.
45. Submit only with an owner-approved test account - each selected file uploads
    before the assessment, the confirmation names Live mode, and a 401 returns
    to sign-in. Never run this check against production without explicit owner
    approval.
46. Open Live history - only records whose established-site `user` matches the
    JWT username and account-scoped user-site records appear; no other username,
    coordinate, media ID, or answer is retained or rendered.
47. Switch between Demo and Live - drafts and history remain isolated; Demo
    submission succeeds in airplane mode and sends no request.

Items 39-47 require on-device verification. Repository tests use fake HTTP only;
they must never be pointed at the production OneAquaHealth base URL.

Type and icon pack (round 3 pick: Baloo 2 + Phosphor):
48. Compare any screen's headline, app-bar title, dialog/bottom-sheet title,
    and button labels against its body text - headings/titles/buttons use the
    rounded Baloo 2 face, body and chip/picture-choice labels stay on Noto
    Sans.
49. Switch to Arabic - every heading still renders in Noto Sans Arabic, never
    Baloo 2 (Baloo 2 has no Arabic glyphs, so this also confirms the fallback
    config is correct rather than silently falling back).
50. Enable airplane mode, clear the app, and relaunch straight into
    onboarding - headings still render in Baloo 2 immediately, with no
    flash-of-fallback-font, since it is bundled rather than fetched.
51. Walk Home, Streams, Check, Impact, and You - no icon renders as a blank
    box or "?" (a missing-glyph symptom); the selected destination's icon is
    visibly bolder/filled, not just a color change.
52. Open the raised Check action, the onboarding data-journey screen's field
    safety notice, and the read-aloud Listen button (before narration starts)
    - each shows its custom water icon (stream-check, field-safety shield
    with a drop, narration speaker with a ripple wave) rather than a generic
    Phosphor glyph.
53. Open `/debug/mascot` -> "Water icon set" - all six custom icons render
    distinctly at both regular and filled weight with no clipped or
    overlapping strokes.
54. Open Settings -> Credits (once built) - Phosphor Icons (MIT) and Baloo 2
    (SIL Open Font License 1.1) are both listed.

Items 48-54 require on-device verification.

Map home and site detail:
55. Open Home - a water-first MapLibre map loads over the pilot area, with
    Nearby/Needs data/Visited filter chips, a Demo/Live badge in the app bar,
    and the OpenFreeMap attribution visible (top-right) at all times.
56. Toggle the phone's light/dark mode while on Home - the map switches
    between the bundled light and dark "water-first" styles without a blank
    frame.
57. Tap Needs data, then Visited - the map and pin count change to match;
    tapping Nearby returns every site. An empty filter result shows a guiding
    Ripple with a "Show all streams" action back to Nearby.
58. Tap a cluster - the camera zooms to exactly the level it splits at. Tap an
    individual pin - a preview card appears at the bottom with the stream
    name, estimated walk time, and Needs data/Visited status; the OpenFreeMap
    attribution stays visible above it, never covered.
59. Tap the locate-me control with location permission denied - a friendly
    message appears ("Location isn't available right now...") and the map
    keeps working; grant permission and tap again - the map centers on the
    device and the site list re-sorts nearest-first.
60. Turn off device location services entirely, then tap locate-me - the same
    friendly message appears, no crash.
61. Switch to airplane mode in Live mode and open Home - a friendly
    "No connection" message appears with Retry; turning connectivity back on
    and tapping Retry loads the map.
62. From a pin's preview card, tap into the stream - site detail shows the
    human-readable name first with the research code secondary (and city when
    known), a "last checked" freshness cue based on your own history for that
    site, and a short safety note under "Before you go".
63. On site detail, tap "Get directions" - the device's maps app opens
    (geo intent on Android) centered on the stream; with no maps app
    installed, a friendly message appears instead of a crash.
64. On site detail, tap "Check this stream" - the real question flow opens
    directly on channel form (no more placeholder), full-screen with no
    bottom nav.

Items 55-64 require on-device verification (the MapLibre view itself is not
exercised by automated tests; see `test/features/home/`).

Round 4: stream-check question flow (`lib/features/check/`):
65. Open the Check tab with no site context - a "Which stream?" picker
    lists nearby sites and offers "Add a new site"; tapping either a site
    or "Start checking this site" (after naming it and tapping "Use my
    current location") opens the question flow for that site.
66. Work through channel form, bottom type, and bank type - each renders a
    2-column grid of the original illustrated cards (never OneAquaHealth's
    own photos), plus an "I'm not sure" link beneath that shows a short
    coaching line once tapped.
67. On Habitats and Natural Debris - the screen opens on a Yes/No gate
    ("Are there any habitats present?"); tapping Yes reveals the
    multi-select chip list, tapping No skips straight past with nothing
    selected.
68. On every yes/no question (water abstraction, dams, pipes, sewage,
    construction, the riparian items, vegetation cuts) - Yes/No/"I'm not
    sure" render as three chips, never a plain Material switch.
69. On the riparian step - a "Facing downstream" primer appears first,
    then Impervious Areas and Vegetation Coverage each show Left and
    Right margin side-by-side; marking a margin's vegetation "Yes" reveals
    that side's own vegetation-type chips; flipping it back to "No" (or
    "I'm not sure") hides and clears that side's type answer.
70. On Invasive Species, answer "Yes" - a "Which ones?" text field appears
    directly beneath; switching back to "No" hides it again.
71. On Overall assessment - Next stays disabled until one of Good/
    Moderate/Poor is tapped (this is the only required question in this
    flow); each card shows its own one-line descriptor.
72. On the feelings screen - joy, serenity, anger and fear each have their
    own independent 0-5 row and a "Not applicable" checkbox; checking it
    zeroes that feeling only, and tapping any level un-checks it.
73. On any question, tap Listen - the prompt reads aloud with word
    highlighting (English), then the options; on a locale with no
    generated narration, the control instead shows "Listen (Device
    voice)" and uses the phone's own TTS with no highlighting.
74. Underlined words (channel, bottom, banks, margin/riparian, invasive)
    open a bottom sheet with a plain-language explanation, a small
    original illustration, and its own Listen control.
75. Answer a few questions, then tap the exit icon (top-right) - a "Save
    and exit?" dialog appears; "Save and exit" returns to the map. Reopen
    the same site's "Check this stream" - a "Pick up where you left off?"
    dialog offers to continue (restoring every prior answer) or start
    over (clears that site's draft back to blank).
76. Reach the end of the feelings screen and tap Next - a "Your answers so
    far" screen lists every answered question with its answer (or "Not
    answered yet"/"Not sure"); this is a deliberate placeholder for the
    next round's photo capture, review, and submit/celebration.
77. Turn on reduce motion and repeat next/back through a few questions -
    transitions become a short dissolve instead of the shared-axis slide.
78. Switch to Arabic (or another RTL-capable locale) mid-flow - question
    copy and chrome fall back to English per-string wherever the protocol
    or ARB has no translation yet (see `assets/data/assessment-content.json`
    `localeStatus`), never a blank or broken row.

Items 65-78 require on-device verification; the shell's navigation,
gating, resume/start-over, and conditional-visibility logic are covered by
`test/features/check/`.
