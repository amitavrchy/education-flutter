# PROGRESS — EduMentor AI Flutter app

Handoff log for multi-session work. Read this first, then `docs/product/FEATURE_MATRIX.md`.

## Ground rules
- Spec: `docs/MASTER_PROMPT.md` (never edit). This repo = Flutter student app + mobile role views.
- Flutter 3.50.1 at `~/development/flutter/bin` (add to PATH). Material comes from
  `package:material_ui/material_ui.dart`, not `flutter/material`.
- Commit coherent chunks locally; never push.
- Before committing: `flutter analyze` (must be clean) and `flutter test`.

## Architecture in one screen
- `lib/core/`: config, l10n (`Tr` bilingual strings + `S` common dictionary), theme tokens,
  `LocalStore` (Hive CE, one box) + `JsonCollection` (seeded typed collection),
  `MockSimulator` (latency, offline, injected errors), `AppSettings`.
- Each feature lives in `lib/features/<name>/{domain,data,application,presentation}` + `<name>_strings.dart`.
- Mock seeds live in `lib/mock/seed/`. Controllers watch `watchStore(ref)` so "Reset demo data"
  (Settings) rebuilds everything from the seeds.
- Navigation: `app/navigation/portal_config.dart` (tabs + grouped "more" menu per role),
  `app/router/app_routes.dart` (all paths), `app/router/app_router.dart` (tab child routes and
  full-screen module routes). Routes for modules not yet built show `FeaturePlaceholderScreen`
  through `_pending(...)` in the router. Replace those lines as modules land.
- Student tabs: Home · Learn · AI Tutor · Practice · More.

## Log
### Session 1 (earlier)
Scaffold, auth (mock + API), theme, router, curriculum seed (SSC/HSC subjects), progress model,
notifications inbox, shared widgets. Left uncompiled mid-refactor without progress docs.

### Session 2 (2026-11-23)
- Fixed build (pub get, settings screen), analyzer clean, 20 tests passing.
- Settings rewritten: theme, language, text size, contrast, reduced motion, Bangla numerals
  (`NumeralScope`), hide leaderboards, offline/error simulation, storage, reset demo data.
- Curriculum journey complete: subject → chapter detail → topic lesson → mark complete (XP).
- Student navigation restructured; Practice hub; grouped More menu; full route table.
- Created FEATURE_MATRIX.md and this file.

## Next (in order)
1. Question bank + practice session (all question types, answer UI, bookmarks, report)
2. Exams (setup, taking, results, history) → feed `learningProgressProvider`
3. AI tutor (conversations, mock RAG engine, modes, streaming, conversions)
4. Dashboard on live data
5. Notes, flashcards (spaced repetition)
6. Planner; analytics/adaptive screen; gamification screen
7. Board + institution archives; search
8. Voice tutor, photo solver, handwriting, library, labs, English, audio, offline
9. Onboarding/signup/OTP/role switcher; profile/subscription/privacy/support
10. Parent + teacher views; contracts/ JSON schemas; remaining docs (spec §57)
