# Track alignment: Track 1 — Citizen Science UX

OneAquaHealth Citizen Science is built for the point where a research protocol meets a person standing beside an urban stream. It keeps the original nine-step protocol and data contract, while changing how the purpose, questions, uncertainty, evidence, and submission result are presented.

## Making participation understandable

Five short onboarding screens explain the urban-stream problem, the One Health connection, what a field check involves, how researchers use observations, and basic bank-side safety. Exploration is available through **Look around first**, so the purpose and local streams can be understood before registration. Human-readable stream names lead the interface; research codes remain available as secondary identifiers.

Errors use plain-language recovery messages for wrong credentials, expired sessions, missing connectivity, timeouts, and server failures. Raw exceptions, response bodies, and status codes are not shown to citizens.

Read-aloud is optional and never starts by itself. The bundled Piper `alba` English narration provides a natural voice, word-by-word visual highlighting, Listen/Pause/Replay controls, audio-interruption handling, and synchronized Ripple mouth cues. Assessment questions and options are also covered. When a generated recording is unavailable, the control is explicitly labelled **Listen (Device voice)** and uses the voice installed on the device.

## Reaching more citizens

The interface and protocol cover 18 languages: English, Greek, Portuguese, Dutch, Norwegian, French, Italian, Spanish, German, Polish, Romanian, Bulgarian, Turkish, Ukrainian, Arabic, Finnish, Swedish, and Croatian. Arabic has a deliberate right-to-left layout, reading order, typeface, progress direction, and mirrored navigation semantics, while physical map and camera controls retain their meaning. Missing per-string translations fall back to English rather than leaving a screen blank.

Accessibility is part of the component contract: semantic labels and reading order, non-colour-only selected and health states, large-text layouts, 48 dp touch targets, light and dark themes, and reduced-motion alternatives that preserve the final meaningful state. Read-aloud continues to work when decorative motion is reduced.

## Supporting fieldwork and useful evidence

The assessment protocol and localized content are bundled. Drafts persist locally, Demo mode works offline, and Live submissions that cannot finish are kept in a local queue. Uploaded-file progress is retained, retries use backoff, and the app retries on launch, restored connectivity, or a manual action. Fresh Live site discovery and map tiles still need connectivity; offline mode does not claim a complete offline basemap.

Evidence support is designed to improve usefulness without turning optional observations into barriers:

- the in-app camera assigns upstream, downstream, surroundings, and biodiversity roles;
- photos are oriented, resized, compressed, and checked on-device for darkness, overexposure, blur, and low-detail obstruction;
- quality findings suggest a retake but allow a citizen to keep valid evidence;
- GPS compares the observed position and accuracy with the selected stream, asking for human confirmation when the fix is poor or clearly far away rather than silently blocking submission;
- the review screen groups answers and shows an 11-item completeness meter with the next useful missing detail;
- only the protocol’s genuinely required answer blocks submission; optional evidence stays optional.

## Motivation without competition

The app uses a weekly contribution rhythm with one grace week, five evidence badges derived from completed history, and factual receipts that state what was recorded and how researchers can use it. It has no public leaderboard, speed bonus, reward per upload, or daily-only streak. These exclusions are deliberate: field safety, uncertainty, privacy, and evidence quality matter more than submission volume.

## A safe path from evaluation to contribution

Demo and Live are visibly different modes with separate storage. Demo contains local sites, seeded personal history, drafts, badges, and simulated submission success, making the whole experience reviewable without credentials or writes. Live requires a real OneAquaHealth account and uses real site data, file uploads, submissions, and account-scoped history. A confirmation precedes the switch, and the persistent badge reduces the risk of confusing a demonstration with a real contribution.

This aligns with Citizen Science UX by addressing the complete participation loop: understand the purpose, find a relevant place, collect evidence with guidance, express uncertainty honestly, review before sending, recover from field conditions, and see a truthful record of the contribution.
