# PROGRESS — EduMentor AI Flutter app

Handoff log for multi-session work. Read this first, then `docs/product/FEATURE_MATRIX.md`.

## Ground rules
- Spec: `docs/MASTER_PROMPT.md` (never edit). This repo = Flutter student app + mobile role views.
- Flutter 3.50.1 at `~/development/flutter/bin` (add to PATH). Material comes from
  `package:material_ui/material_ui.dart`, not `flutter/material`.
- Commit coherent chunks (author amitavrchy). Push when the user asks.
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

### Session 4 (2026-11-24) — parity with the web app
Product decisions (same as the web repo):
- Institution portal removed: the institution admin role and the institution exam type are gone.
  - Kept: the school/college question archive and a student's school name.
- No guardian consent: students of any age sign up on their own. Guardians see only what the student shares.

Built (each with tests; analyzer clean; 122 tests):
- **Book avatar teacher** (`lib/features/book_avatar/`):
  - Per-book animated 2D teacher, ported from the web SVG avatar.
  - Ask by text or voice (`speech_to_text`); answers are spoken (`flutter_tts`) with lip-sync and captions.
  - Answers come only from the book, with page citations that open the reader.
  - Includes history, feedback and reports.
  - Teacher view: test chat and report fixes. Parent view: usage counts only.
  - Mic and speech permissions added for Android and iOS.
- **Library**: book list and detail, page reader, bookmarks, continue reading, offline download.
- **Live student dashboard**, adaptive analytics, achievements (XP, levels, badges, missions, demo leaderboard).
- **Board archive and school/college archive**:
  - Board-style sample papers: 9 boards × 10 years, with HSC 2020 omitted.
  - Demo school/college directory.
  - Every paper can be practised as a set.
- **Global search** with grouped results and recent searches.
- **Account**: profile, subscription (simulated checkout with coupons), privacy (sharing, export, deletion), help and tickets.
- **AI tools**: voice tutor, photo solver (simulated OCR), handwriting evaluation (AI estimate).
- **Study tools**: English coach, labs (motion, Ohm's law, periodic table, quadratic plotter), audio revision, offline downloads.
- **Teacher portal**:
  - Classes, evaluation queue, assignments.
  - Publishing quizzes that students see.
  - AI question generator, materials, analytics.
- **Parent portal**: overview, link a child with the demo OTP, progress, results and reports. All views honour the student's privacy settings.
- **Auth**: welcome, signup, OTP (`123456`), password reset, onboarding.

Bugs fixed along the way:
- The question seed gave physics questions subject `ssc` (it used `indexOf('-p')`).
- The English coach produced "gos"/"haves".
- The planner TabBar alignment was wrong.
- Voice screens read a provider inside `dispose()`.
- The shared test helpers now use in-memory token storage.

No placeholder routes remain. Admin work (avatar editing, content management) stays on the web.

## Continue on another PC
1. `git clone https://github.com/amitavrchy/education-flutter.git && cd education-flutter`
2. `flutter pub get && flutter analyze && flutter test` (do not change the global Flutter SDK)
3. Start Claude Code in the repo and say: *"Read docs/MASTER_PROMPT.md, PROGRESS.md and
   docs/product/FEATURE_MATRIX.md; continue implementing the remaining incomplete features."*

## Next (in order)
1. Connect the real API: repositories already sit behind interfaces. Avatar contract: web `docs/api/BOOK_AVATAR_CONTRACT.md`.
2. Remaining ⬜ rows in `docs/product/FEATURE_MATRIX.md`: page notes/highlights, timed board paper, crop/multi-image, friend challenges, sync conflict UI.
3. Device QA of voice (Bangla TTS/STT availability varies by phone) and accessibility pass.
