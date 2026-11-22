# ShikkhaAI — Mobile (Flutter)

Android/iOS app for **students, teachers and parents**. Institution admins and super admins use the
web dashboard; the app shows them a "use the web" screen.

**Stack:** Flutter 3.50 (Dart 3.14) · Material 3 via `material_ui` · Riverpod 3 · go_router 18 ·
Dio · flutter_secure_storage · google_fonts (Hind Siliguri, Bangla) · mocktail

> **Status: not compiled yet.** This project was written on a machine without the Flutter SDK, so
> `flutter analyze`, the tests and a build have **not** been run. Do the setup below once and
> fix anything the analyzer reports before building features on top.

## One-time setup

1. Install Flutter **3.50+** (stable) and run `flutter doctor`.
2. Generate the native platform folders (`android/`, `ios/`). Existing files in `lib/` and `test/` are kept:
   ```bash
   cd mobile
   flutter create . --project-name shikkhaai_mobile --org com.shikkhaai --platforms android,ios
   ```
3. Install packages and check the code:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```
4. Android networking (in the generated `android/` folder):
   - `android/app/src/main/AndroidManifest.xml`: add
     `<uses-permission android:name="android.permission.INTERNET"/>`. Release builds need it.
   - To call the local backend over plain `http://` from the emulator, add
     `android:usesCleartextTraffic="true"` to `<application>` in
     `android/app/src/debug/AndroidManifest.xml`. Debug only; production uses HTTPS.

## Run

```bash
flutter run --dart-define-from-file=config/dev.json
```

| Variable (`config/dev.json`) | Default | Meaning |
| --- | --- | --- |
| `API_BASE_URL` | `http://10.0.2.2:4000/api/v1` | Backend URL. `10.0.2.2` is the host's localhost seen from the Android emulator; use `http://localhost:4000/api/v1` on the iOS simulator and your PC's LAN IP on a real phone. |
| `USE_MOCK_API` | `true` | `true` = offline mock repositories, `false` = real backend |
| `APP_NAME` | `ShikkhaAI` | App title |

**Demo mode** (`USE_MOCK_API=true`): sign in as `student@…`, `teacher@…` or `parent@…` with any password of 8+ characters.
`institution@…` and `admin@…` show the web-only screen.
With `USE_MOCK_API=false`, login calls the backend, whose auth endpoints currently answer **501 (not implemented)**.

## Structure

```
lib/
├── main.dart                 ProviderScope + 401 → sign-out wiring
├── app/
│   ├── app.dart              MaterialApp.router, themes, Bangla locale
│   ├── router/               go_router setup, routes, pure auth redirect (unit-tested)
│   ├── navigation/           portal_config.dart — tabs + "more" menu per role (single source of truth)
│   └── shell/                RoleShell — bottom NavigationBar, one stack per tab
├── core/                     no feature imports allowed here
│   ├── config/               Env (--dart-define values)
│   ├── constants/            app + secure-storage keys
│   ├── network/              ApiClient (Dio), ApiResponse/ApiException (backend envelopes), AuthInterceptor
│   ├── storage/              TokenStorage (Keychain / Android Keystore)
│   ├── theme/                colors, spacing/radius tokens, light/dark ThemeData, theme-mode controller
│   └── utils/                Bangla digits, form validators (BD phone numbers)
├── features/
│   ├── auth/                 domain (AppUser, UserRole) · data (API + mock repositories) · application (AuthController) · presentation (splash, login, unsupported role)
│   ├── dashboard/            student / teacher / parent home screens (sample numbers, marked "ডেমো ডেটা")
│   ├── ai_tutor/             repository wired to POST /ai/tutor/ask · placeholder screen
│   ├── more/                 per-portal feature menu
│   ├── notifications/        inbox placeholder
│   └── settings/             account, theme mode, logout
└── shared/widgets/           AppPageScaffold, EmptyState, ErrorView, LoadingView, StatCard/StatGrid, SectionHeader, FeaturePlaceholderScreen
test/                         utils, API envelope parsing, auth redirect, user parsing, login widget test
config/                       dev.json (safe defaults), dev.example.json
assets/                       images · icons · illustrations · fonts
```

### Navigation

| Role | Bottom tabs | "More" menu |
| --- | --- | --- |
| Student | Home · AI Tutor · Practice · Progress · More | Library, Question bank, Photo solver, Notes, Study planner, Videos, Practical lab, Scholarships, Career, Notices |
| Teacher | Home · Classes · Evaluation · More | Assignments, Exams, AI question generator, Materials, Analytics |
| Parent | Home · Children · Progress · More | Reports, Results |

Routes are `/<role>/<tab>` and `/<role>/more/<feature>`, plus `/settings` and `/notifications`.
The router keeps each user inside their own portal.

### Conventions

- **Feature layout:** `domain/` (models) → `data/` (repositories: an interface plus API and mock implementations) → `application/` (Riverpod Notifiers) → `presentation/` (widgets).
- **Imports:** import Material from `package:material_ui/material_ui.dart`, not `package:flutter/material.dart` (Material left the framework in Flutter 3.47).
- **Networking:** repositories call `ApiClient` and get typed data or an `ApiException`. They never touch Dio directly.
- **Secrets:** tokens live only in `TokenStorage` (secure storage), never in SharedPreferences or logs.
- **Data:** student data is private. The backend enforces access; the app only shows what the API returns.

## Next steps

1. Run the setup above and fix any analyzer findings.
2. Bundle Hind Siliguri under `assets/fonts/` (offline Bangla text instead of runtime download).
3. Add refresh-token rotation in `AuthInterceptor` once the backend's `/auth/refresh` exists.
4. Build the AI tutor chat, practice/exams and progress screens.
5. Add push notifications (Firebase Cloud Messaging) and crash reporting.
