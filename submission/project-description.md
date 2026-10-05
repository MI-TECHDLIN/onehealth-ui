# Project description

## Problem

Urban streams connect ecosystem condition, biodiversity, public space, and human well-being, but researchers cannot continuously observe every site. Citizen observations can extend that view when the protocol is understandable and the evidence is useful.

The existing OneAquaHealth citizen flow contains a substantial scientific protocol, but it presents several participation barriers: registration comes before exploration; research codes can dominate place names; the long form offers limited contextual coaching; a partially translated flow can fall back to English; and network or server failures are difficult to act on in the field. The original client also gives little feedback about photo usefulness, location confidence, overall completeness, or what happens after submission.

## Solution

OneAquaHealth Citizen Science is a Flutter redesign of that field experience. It preserves the protocol and payload semantics while adding:

- five-screen purpose and safety onboarding;
- a water-first stream map with names, research codes, filters, site details, and personal visit history;
- one-question-at-a-time guidance, original comparison illustrations, “I’m not sure,” and tap-to-explain glossary terms;
- read-aloud controls with bundled English Piper narration and an explicit device-voice fallback;
- 18 localized interfaces, including Arabic right-to-left behavior and English per-string fallback;
- saved drafts, an offline-aware Live submission queue, on-device photo analysis, GPS confirmation, grouped review, and an evidence completeness meter;
- plain-language error recovery;
- a weekly contribution rhythm, five evidence badges, and factual receipts without leaderboards.

Ripple, a code-drawn water mascot, appears for orientation, narration, loading, recovery, reflection, and celebration. It does not cover evidence or score scientific quality.

## Who it is for

The primary users are residents, families, students, community groups, and returning volunteers observing urban streams. The interface supports a first-time participant who needs context and a repeat contributor who needs quick access to nearby sites, saved work, history, and reminders.

Researchers are downstream users of the evidence. The app preserves site identifiers and protocol fields, collects structured answers and optional media, and sends the existing Live payload rather than inventing a new scientific measure.

## Intended impact

The product is designed to make participation more understandable, inclusive, and resilient in field conditions. Better-labelled photo roles, quality suggestions, GPS confidence, an explicit uncertainty path, and review can improve the practical usefulness of a check. Local drafts and queuing reduce the chance that work is lost when connectivity fails. Read-aloud, large-text behavior, semantic states, reduced motion, multilingual content, and right-to-left layout lower access barriers.

The app makes a bounded claim: observations support OneAquaHealth researchers in monitoring urban freshwater ecosystems and investigating change over time. It does not claim that one submission is scientifically verified, diagnoses ecosystem health, or automatically triggers an alert.

## How it works

### Demo and Live

Demo mode is the default evaluation path. It uses bundled sites and protocol content plus isolated local drafts, history, queues, receipts, and badge state. A seeded story provides several past checks and one resumable draft. Demo submission succeeds locally and does not contact the OneAquaHealth API.

Live mode has a persistent visual badge and requires an actual OneAquaHealth account. It retrieves real sites and reference data, uploads selected files, submits to the established-site or user-generated-site endpoint, and reads only account-scoped history. Demo and Live storage are namespaced so switching modes cannot expose or submit the other mode’s work.

If a Live submission fails, the draft is queued locally. Successfully uploaded file IDs are retained so retries do not restart completed uploads. Retries occur with backoff on app start, restored connectivity, or a manual retry. Protocol content remains available because it is bundled; fresh site discovery and map tiles still require a network.

### Nine-step protocol

1. **Basic information:** explains the check and safety context.
2. **Site:** selects a known or personal stream, or creates a named site with coordinates.
3. **Media:** captures optional upstream, downstream, surroundings, and biodiversity evidence in the current app.
4. **Channel:** records channel form, bed and bank type, habitats, natural debris, and water flow.
5. **Water and alterations:** records water appearance, abstraction, barriers, pipes, discharge, construction, and estimated height.
6. **Margins:** teaches downstream orientation, then records left/right impervious cover and vegetation, dominant vegetation, invasive species, and recent cutting.
7. **Overall health:** requires one Good, Moderate, or Poor observation with a plain-language descriptor.
8. **Feelings:** records independent joy, serenity, anger, and fear values from 0–5, each with a not-applicable option.
9. **Review and submit:** groups the answers, shows photo and GPS evidence plus completeness, states consent, and performs the Demo or Live submission.

The visual flow separates the protocol into focused question pages, but answer IDs and submission fields remain tied to the original steps.

### Data path to researchers

The selected site and structured answers form an `AssessmentDraft`. Photos are processed on-device and attached by evidence role. The review screen checks required fields and displays a completeness summary. In Demo, submission becomes a local history record. In Live, each selected file is uploaded first; returned file IDs are added to the established-site or user-generated-site payload, which is sent with a stable idempotency key. The accepted record becomes a personal receipt and appears in stream history and profile measures. Researchers receive the existing OneAquaHealth assessment structure rather than a separate hackathon-only schema.

## Built during the hackathon

- the shared token-based light/dark design system and accessible component kit;
- Ripple’s five moods, reusable gestures, narration visemes, and reduced-motion states;
- friendly failure classification and reusable error banners;
- the five-screen onboarding and read-aloud pipeline;
- the persistent shell, 18-locale registry, Arabic RTL behavior, mode selection, sign-in, and avatar setup;
- the MapLibre/OpenFreeMap home map, site filters, site details, and personal timelines;
- the data-driven assessment flow, conditional questions, glossary, draft resume, optional evidence capture, photo analysis, GPS confirmation, completeness review, and celebration receipt;
- separate Demo and Live repositories, real Live uploads/submissions, account-scoped history, and queued retry behavior;
- personal streams, history receipts, weekly rhythm, evidence badges, gentle reminders, and resettable judge-demo data;
- automated repository, protocol, routing, localization, accessibility-state, field-quality, and gamification tests, plus a device-focused manual QA checklist.

## Limitations

- English is the reviewed source. The seven original locale bundles retain the supplied OneAquaHealth content, including the original partial Greek coverage; the 11 added protocol locales are machine-assisted. All non-English interface and protocol copy still needs native-speaking domain review, and the app retains an English fallback per string.
- Bundled natural Piper narration currently covers English. Other assessment languages use a device voice, whose availability, quality, and offline behavior depend on the installed operating-system voice.
- Live mode works only with a real OneAquaHealth account. Real uploads and submissions must be demonstrated only with an account authorized for that purpose.
- Live site discovery and OpenFreeMap tiles require connectivity. Queuing protects drafts and submissions, but there is no packaged offline basemap.
- Automated tests replace native camera, location, MapLibre, notification, and text-to-speech integrations with seams. Those behaviors still require the manual device checks listed in `docs/manual-qa.md`.
- Photo checks are lightweight image heuristics that suggest a retake; they are not scientific validation or content recognition.
- GPS checks estimate distance and fix quality, then ask for confirmation. They do not prove that an observation was made at the stream.
- The Impact destination is present in the navigation but is not yet a full aggregate research-impact dashboard. Current impact feedback is limited to personal history, rhythms, badges, stream timelines, and factual submission receipts.
- The original API’s complete server-side validation, retention, moderation, deletion, geolocation privacy, and production idempotency policies need a versioned service contract before a general public release.

## Next

- complete native domain review of all 18 locales and regenerate matching narration after approval;
- add licensed natural voices or native recordings for more languages while keeping device voice as a labelled fallback;
- validate camera, GPS, TTS, notifications, large text, RTL, and MapLibre behavior across the supported device matrix;
- agree a versioned API, staging tenant, retention and consent policy, moderation path, and server-supported idempotency contract with the OneAquaHealth service owner;
- add privacy-preserving aggregate coverage and researcher feedback to the Impact destination once those signals exist in an approved API;
- evaluate opt-in offline map regions without increasing the default app footprint or obscuring tile attribution.
