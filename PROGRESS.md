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

### Session 5 (2026-11-25) — full student/parent/teacher parity with the web
Scope agreed with the owner: every student, parent and teacher feature and flow of the web app,
on mock data (real API later). Admin dashboard and marketing site stay web-only.
Branch `feat/web-parity` (from `origin/main`). Analyzer clean, 190 tests.

- Notifications: role audiences, detail, archive, preferences, push permission UI, simulation, urgent banner.
- Parent: multi-child guardian portal (link code + OTP, per-link sharing, calendar, feedback + reply,
  goals, reports, privacy). The device's student is live data; student privacy always wins.
- Teacher: content review workflow with status flow and role permissions, question authoring,
  rubrics, evaluation stages (AI / teacher / official), per-student submissions, students, history.
- Student: 24 dashboard widgets + customise; adaptive analytics (heatmap, gaps, roadmap); gamification
  (challenges, milestones, celebrations, friend challenges); library notes/highlights/AI explain;
  board + school archives (solved view, timed exam, trends, visibility, duplicates); AI tools
  (voice prefs/history/conversation tools, multi-image photo solver, handwriting OCR + teacher review);
  English coach (all skills + mock exam); 21 labs; audio (podcasts, markers, playlist, downloads);
  offline (conflicts, retry, offline quizzes); preferences + security; consent + session-expired;
  wider search; chapter counts + hierarchy; planner list view.
- Cross-portal links: teacher review → student notification + guardian feedback; student review
  request → teacher queue; guardian reply → teacher inbox.

Still open (honest list): question image assets (QB-06), Bangla-only portal menu/role labels (X-01),
formal accessibility audit (X-02), JSON-schema contracts (X-04), real API wiring.

### Session 6 (2026-11-26) — backend API wiring started
Branch `feat/api-integration`. Run with `--dart-define=USE_MOCK_API=false` (and `API_BASE_URL`,
10.0.2.2 on the Android emulator). Live checks: `LIVE_API=1 flutter test test/live` with the backend
running in demo mode.

- Auth on the real `/auth/*`: login, two-step signup (server OTP challenge), refresh-token rotation
  in `AuthInterceptor`, switch-role, backend role names (reviewers → teacher portal).
- Notifications: server inbox merged with device-raised ones; read/archive/delete/read-all on the server.
- Billing: plan, renewal, invoices from `/billing/me`; checkout/cancel/resume on `/billing/*`.

- Curriculum: in API mode the app pulls the backend's subjects, papers, chapters, topics, outcomes and
  question bank (`CatalogSync`, cached on device), so every id matches the server. The bundled
  curriculum is only used in mock mode and offline before the first sync. 61 server questions point at
  a missing chapter (`ssc-ict-c6`); they are dropped at sync until the backend data is fixed.
- Progress: mastery, chapter progress, activity and attempts load from the server; answers, topic
  completion and study minutes post to `/progress/:studentId/*` (the server computes XP and streaks).
- Question bookmarks, flashcard decks and cards, notes (Tiptap HTML ↔ Markdown), planner tasks and
  book reading state sync through `OwnerSync` (pull, map, merge over the server record, debounced
  PUT), so web-only fields survive a round trip.
- Exams: offered exams and attempts from `/exams` and `/exam-attempts`; start, autosave, submit and
  discard use the exam endpoints; the server scores and records progress.
- AI tutor: conversations, messages and folders from the records API; questions answered by
  `/tutor/:id/.../messages`; regenerate, report, feedback, bookmarks, pin/archive/rename/folder.
- Student profile and guardian sharing switches (`/student-profiles`), the guardian link code
  (`/guardian/link-code`), answer scripts sent for teacher review (`/evaluations`), server XP,
  points, streak and badges, and the English progress document.
- Guardian portal: links, linking with the OTP challenge, unlinking, sharing switches, child
  summaries (only what each link may see), teacher feedback (acknowledge/reply) and goals.
- Teacher portal: classes from class groups and institution members, assignments and grading,
  answer-script review, shared resources, student feedback; content review queue and rubrics.

Stays on the device by design: offline downloads, audio lessons (generated on the phone; the web
has a different lesson catalogue), board/institution paper archive (demo papers), AI tool history,
the book avatar, friend challenges (the server's model differs) and app preferences.
231 tests; live suite 16/16 (`LIVE_API=1 flutter test test/live`, backend in demo mode).

## Continue on another PC
1. `git clone https://github.com/amitavrchy/education-flutter.git && cd education-flutter`
2. `flutter pub get && flutter analyze && flutter test` (do not change the global Flutter SDK)
3. Start Claude Code in the repo and say: *"Read docs/MASTER_PROMPT.md, PROGRESS.md and
   docs/product/FEATURE_MATRIX.md; continue implementing the remaining incomplete features."*

## Next (in order)
1. Device QA in API mode (`--dart-define=USE_MOCK_API=false`) against a deployed backend.
2. Translate portal menu labels and role names (X-01); add question image assets (QB-06).
3. Device QA of voice (Bangla TTS/STT availability varies by phone) and an accessibility pass.
