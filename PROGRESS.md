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

- Question bank + practice sessions + bookmarks/sets (commit 4f437ef).
- Exam system: centre, setup, timed taking with recovery, scoring, results, history (2163ab8).
- AI tutor: mock RAG engine, 10 modes, streaming chat, conversation tools (eb2b151).
- Notes (generator, editor, history, links) and flashcards (SM-2, decks, study) + tutor/note/question conversions.

- Session 3 stopped at the usage limit while building the study planner
  (`lib/features/planner/`, router entry, tests) — committed as WIP, **unverified, run
  `flutter analyze` + `flutter test` first**.

## Continue on another PC
1. `git clone https://github.com/amitavrchy/education-flutter.git && cd education-flutter`
2. `flutter pub get && flutter analyze && flutter test` (do not change the global Flutter SDK)
3. Start Claude Code in the repo and say: *"Read docs/MASTER_PROMPT.md, PROGRESS.md and
   docs/product/FEATURE_MATRIX.md; continue implementing the remaining incomplete features."*

## Next (in order)
1. Dashboard on live data
2. Planner (WIP — finish first); analytics/adaptive screen; gamification screen
3. Board + institution archives; search
4. Voice tutor, photo solver, handwriting, library, labs, English, audio, offline
5. Onboarding/signup/OTP/role switcher; profile/subscription/privacy/support
6. Parent + teacher views; contracts/ JSON schemas; remaining docs (spec §57)
