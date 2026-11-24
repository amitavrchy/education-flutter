# Feature Matrix — EduMentor AI Flutter app

Scope of **this repo**: the Flutter student app (all student features, spec §48) plus the
mobile views for parent and teacher/reviewer roles (the institution portal was removed by product
decision on 2026-11-24). The admin dashboard
(spec §30–42, §46–47) and the marketing website belong to the separate web repo; they are
listed at the end so every spec feature stays tracked.

**Status legend.** A feature is ✅ only when its whole journey works against the mock layer,
including loading, empty and error states.
- ✅ done: journey works, persisted, states covered
- 🟡 partial: screen exists, but some interactions or states are missing (see notes)
- ⬜ not started: route may show the "being built" placeholder
- 🌐 web repo: not in the mobile scope

**Test column:** U = unit test, W = widget test, — = untested.

Shared plumbing used by every row: `LocalStore` (Hive CE) → `JsonCollection` → mock
repositories, with `MockSimulator` adding latency and the offline/error demo toggles.
Loading uses skeletons through `AsyncValueView`; errors use `ErrorView` (offline, denied,
generic with retry).

## M01 Authentication & onboarding (§6)

| ID | Feature | Role | Flutter screen | Mock source | Status | Test |
|---|---|---|---|---|---|---|
| AUTH-01 | Welcome screen | all | — | — | ⬜ | — |
| AUTH-02 | Email / phone login with validation | all | `LoginScreen` | `MockAuthRepository` | ✅ | W |
| AUTH-03 | Signup | student/parent | — | — | ⬜ | — |
| AUTH-04 | Mock OTP verification | all | — | — | ⬜ | — |
| AUTH-05 | Password recovery / reset UI | all | — | — | ⬜ | — |
| AUTH-06 | Remember session / restore | all | `SplashScreen` | `TokenStorage` | ✅ | W |
| AUTH-07 | Logout (with confirm) | all | Settings | — | ✅ | — |
| AUTH-08 | Session expiry simulation (401 → sign out) | all | interceptor | — | ✅ | U |
| AUTH-09 | Demo role switcher | all | — | — | ⬜ | — |
| AUTH-10 | Account deletion request | student | — | — | ⬜ | — |
| AUTH-11 | Language selection | all | Settings | `AppSettings` | ✅ | — |
| AUTH-12 | Privacy notice (guardian consent for under-18s removed 2026-11-24: any age signs up alone) | student | — | — | ⬜ | — |
| AUTH-13 | Onboarding wizard (19 fields, steps, validation, save/resume, review, completion) | student | — | `StudentProfile` (model only) | ⬜ | — |

## M02 Student dashboard (§7)

| ID | Feature | Status | Notes |
|---|---|---|---|
| DASH-01..24 | 24 widgets (greeting, goal, weekly chart, streak, recommendations, continue, exams, quick tutor, recent chats, weak topics, revision, sessions, subject performance, completion, daily quiz, saved questions, model tests, achievements, notices, subscription, calendar, notifications, resources, summary) | 🟡 | Only the greeting, hard-coded stats and quick actions exist; must read live state |
| DASH-25 | Customise / reorder widgets | ⬜ | `AppSettings.dashboardOrder/hiddenWidgets` already persisted |

## M03 AI private tutor (§8)

| ID | Feature | Status | Notes |
|---|---|---|---|
| TUT-01 | Conversations: new, history, search, rename, delete, pin, archive, folders; group by date/subject/chapter/folder | ✅ U | `AiTutorScreen`, `TutorController` |
| TUT-02 | Messages: timestamps, markdown, math, code, tables, copy, regenerate (with correction history), edit question | ✅ U/W | |
| TUT-03 | Context sheet: level, class, subject, paper, chapter, topic, curriculum version, language (bn/en/mixed), mode; chips show active context; deep links from curriculum/questions | ✅ U | context changes retrieval (tested) |
| TUT-04 | 10 teaching modes with distinct output (incl. Socratic, board answer, oral exam grading, English coach corrections) | ✅ U | |
| TUT-05 | Mock RAG over 19 original sample-textbook passages; source cards; viewer with highlight; verified / partial / general / unavailable + simulated label | ✅ U/W | |
| TUT-06 | Follow-ups, related questions, 👍/👎, bookmark, report, teacher review queue, confidence, low-confidence / missing / conflicting / old-curriculum warnings, integrity + off-topic safety | ✅ U | |
| TUT-07 | Convert to notes / quiz / flashcards; Markdown export (clipboard); safe share (name hidden by default, simulated link) | ✅ U | |
| TUT-08 | Simulated streaming, stop, retry, offline/error states, interrupted-stream recovery | ✅ U | |

## M04 Voice tutor (§9) · M05 Image solver (§10)

| ID | Feature | Status |
|---|---|---|
| VOICE-01..30 | Simulated voice session state machine, waveform, transcript, modes, history, limits | ⬜ |
| IMG-01..19 | Pick/capture, preview, rotate/crop, multi-image, validation, simulated OCR, correction, solve, save | ⬜ |

## M06 Curriculum explorer (§11)

| ID | Feature | Status | Test |
|---|---|---|---|
| CUR-01 | Subject catalogue (mine / all), search across subjects, chapters, topics | ✅ | — |
| CUR-02 | Subject overview, papers, chapter list with mastery | ✅ | — |
| CUR-03 | Chapter detail: description, duration, difficulty, relevance, prerequisites, outcomes, history | ✅ | — |
| CUR-04 | Topic lesson, mark complete (XP + activity), next topic, quick check, ask tutor | ✅ | — |
| CUR-05 | Continue / resume learning | ✅ | — |
| CUR-06 | Resource / question counts per chapter | ⬜ | question bank now exists; counts not yet shown |

## M07 Textbook library (§12) · M08 Question bank (§13) · M09 Board archive (§14) · M10 Institution archive (§15)

| ID | Feature | Status |
|---|---|---|
| LIB-01..27 | Browse/filter books, reader, TOC, page nav, zoom (text size), bookmarks, continue reading, offline download, ask the book's avatar teacher, citation deep links | 🟡 ✅ U+W for these; page notes & highlights ⬜ |
| QB-01 | Question model: 15 types incl. CQ ক/খ/গ/ঘ, matching, fill-in, proof, case/passage | ✅ U |
| QB-02 | Browse/filter/sort (subject, chapter, type, difficulty, source, year, board, marks, verified, relevance, search; recent/difficulty/frequency), pagination | ✅ U |
| QB-03 | Answer reveal, explanation, steps, alt method, rubric, citations, self-mark right/wrong | ✅ |
| QB-04 | Bookmark, practice sets CRUD, report, copy, print view, history, reattempt wrong, topic coverage, related | ✅ U/W |
| QB-05 | Practice session: quick / daily (weak topics) / mixed / wrong / bookmarks / set; instant check; updates mastery + XP | ✅ U/W |
| QB-06 | Image/diagram assets inside questions | ⬜ (diagram questions are text-described) |
| BOARD-01..25 | Board/year/subject explorer, paper viewer, solutions, frequency analysis, timed paper, authenticity labels | ⬜ |
| INST-01..18 | Institution directory, filters, papers, categories, visibility, duplicates, report | ⬜ |

## M11 Exams (§16) · M12 Handwriting evaluator (§17)

| ID | Feature | Status |
|---|---|---|
| EXAM-01 | 13 exam types (templates seeded for model, daily, teacher, board-sample, full, oral; institution exam type removed; chapter/subject/custom/adaptive from setup) | ✅ |
| EXAM-02 | Setup: subject, chapters, types, count, difficulty, time, negative marking, mode, randomise, review policy; live pool validation | ✅ |
| EXAM-03 | Taking: immersive focus mode, timer + autosave, palette, mark for review, prev/next, keyboard shortcuts, written editor, handwritten photo upload, submit confirm, time-up auto-submit, recovery | ✅ U/W |
| EXAM-04 | Results: score, grade/GPA, counts, time, accuracy, difficulty/topic analysis, question review, weak areas → lessons/practice, teacher feedback, retake, printable, history + trend chart | ✅ U/W |
| EXAM-05 | Submit propagates to practice history, mastery, study log/XP and a result notification | ✅ U |
| HW-01..22 | Upload pages, reorder, simulated OCR, correction, rubric score, AI vs teacher vs official marks | ⬜ |

## M13 Planner (§18) · M14 Adaptive learning (§19) · M15 Flashcards (§20) · M16 Notes (§21)

| ID | Feature | Status |
|---|---|---|
| PLAN-01..29 | Daily/weekly/monthly plans, calendar, timeline, tasks, reschedule, generation, insights | ⬜ |
| ADAPT-01..23 | Mastery by topic/subject (model ✅), trends, heatmap, weak/strong, roadmap, recommendations | 🟡 (model + exam weak areas) |
| FC-01 | Decks: manual, from chapter (AI), notes, conversation, wrong answers; rename/delete | ✅ U |
| FC-02 | Cards: add/edit/delete, bookmark, search, filter (due/new/bookmarked/learned) | ✅ |
| FC-03 | Study mode with flip animation (reduced-motion aware), again/hard/good/easy with interval preview, known/unknown, quick review (no scheduling), daily queue across decks, stats | ✅ U/W |
| FC-04 | Deterministic simplified SM-2 scheduler | ✅ U |
| NOTE-01 | Dashboard: search, folders, tags, favourites, chapter filter | ✅ |
| NOTE-02 | Generate (simulated AI) from chapter / topic / question / conversation / upload (file validation); 7 note types | ✅ U |
| NOTE-03 | Editor: markdown toolbar, preview, autosave, version history + restore, linking, tags, folder, copy, printable/PDF view | ✅ U |

## M17 English coach (§22) · M18 Labs (§23) · M19 Audio (§24) · M20 Gamification (§25) · M21 Offline (§26)

| ID | Feature | Status |
|---|---|---|
| ENG-01..18 | Grammar, vocabulary, writing feedback, reading, listening, speaking (simulated) | ⬜ |
| LAB-01..21 | Physics, chemistry, biology and maths interactive labs, calculator | ⬜ |
| AUD-01..17 | Audio library, player, speed, transcript, markers, playlist, progress | ⬜ |
| GAME-01..17 | Streak (✅ model), XP/levels (✅ model), badges, missions, leaderboards (hideable) | 🟡 (model only) |
| OFF-01..15 | Downloads, storage, sync status, conflicts, offline badges | 🟡 (offline simulation toggle + banner ✅) |

## M22 Parent (§27) · M23 Teacher/reviewer (§28) · M24 Institution (§29)

| ID | Feature | Status |
|---|---|---|
| PAR-01..20 | Guardian onboarding, linking, child overview, progress, privacy (no consent step) | 🟡 (static home only; avatar usage ✅) |
| TEA-01..21 | Review queue, status flow, question CRUD, quizzes, assign, review submissions | 🟡 (static home only) |
| INS-01..25 | Institution portal | 🚫 removed (product decision 2026-11-24); role dropped from the app |

## M29 Per-book live 2D avatar teacher (product requirement, 2026-11-24)

Code: `lib/features/book_avatar/` (engine, controller, voice, painter, screens). Same contract
as the web (`docs/api/BOOK_AVATAR_CONTRACT.md` in the web repo). Editing an avatar's look,
voice and scope is an admin task, which stays on the web.

| ID | Feature | Role | Flutter screen | Status | Test |
|---|---|---|---|---|---|
| AVT-01 | One avatar per sample textbook, varied look/name per book | all | `AvatarGalleryScreen` | ✅ | U |
| AVT-02 | Animated 2D teacher: breathing, blinking, lip-sync, listening/thinking/speaking cues, reduced motion | all | `TeacherAvatar` | ✅ | W |
| AVT-03 | Ask by text | student | `AvatarClassroomScreen` | ✅ | W |
| AVT-04 | Ask by voice (speech_to_text), hands-free, sample questions when recognition is unavailable | student | `AvatarClassroomScreen` | ✅ | — |
| AVT-05 | Spoken answers (flutter_tts) with captions, speed, mute; silent lip-sync when no voice | student | `AvatarClassroomScreen` | ✅ | — |
| AVT-06 | Answers only from the book, with page citations and a page viewer | student | `AvatarClassroomScreen` | ✅ | U+W |
| AVT-07 | Out-of-book questions declined with book-topic suggestions; chapter scope respected | student | engine | ✅ | U |
| AVT-08 | Class history, helpful/not helpful, report a wrong answer | student | `AvatarClassroomScreen` | ✅ | U |
| AVT-09 | Teacher: avatar profile + test chat; resolve/dismiss reported answers | teacher | `TeacherAvatarsScreen` | ✅ | U+W |
| AVT-10 | Parent: usage counts only (no transcripts) | parent | `ParentAvatarActivityScreen` | ✅ | U |
| AVT-11 | Offline: avatar disabled with a clear message | student | `AvatarClassroomScreen` | ✅ | U |

## M25 Notifications (§43) · M26 Profile & settings (§44) · M27 Search (§45)

| ID | Feature | Status | Test |
|---|---|---|---|
| NOTIF-01 | Inbox, read/unread, mark all, filter, delete, deep link | ✅ | — |
| NOTIF-02 | Detail view, preferences, push/email permission UI, in-app simulation | ⬜ | |
| SET-01 | Theme (light/dark/system), language, text size, high contrast, reduced motion, Bangla numerals | ✅ | — |
| SET-02 | Demo tools: simulate offline / server errors; storage usage; reset demo data | ✅ | — |
| SET-03 | Profile (personal, academic, preferences, goals), subscription, billing, privacy, guardian, help, feedback, deletion | ⬜ | |
| SRCH-01 | Global search across all content, suggestions, recent, popular, filters, grouping | ⬜ | |

## M28 Cross-cutting (§49–55)

| ID | Feature | Status |
|---|---|---|
| X-01 | Bangla/English UI via `Tr` dictionaries | 🟡 older screens (login, dashboards) still hard-code Bangla |
| X-02 | Accessibility: semantics on cards, progress, banners; text scaling; reduced motion | 🟡 |
| X-03 | Mock data consistency (exam → analytics, completion → progress, bookmarks, notes) | 🟡 completion/practice/exam → progress ✅, exam → notification ✅ |
| X-04 | Platform-neutral contracts (`contracts/*.schema.json`) | ⬜ |
| X-05 | Docs set from spec §57 (mobile subset) | 🟡 this file + PROGRESS.md |

## Web repo scope (tracked, not built here) 🌐

Admin dashboard and management (§30–42), content coverage admin view (§46), marketing
website (§47), and the web student app (§3A). The mobile app keeps API-ready repository
interfaces so the same backend serves both.
