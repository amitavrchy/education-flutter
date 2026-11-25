import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/local_store.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/section_header.dart';
import '../ai_tutor/domain/tutor_models.dart';

abstract final class PrefStrings {
  static const learning = Tr('শেখার পছন্দ', 'Learning preferences');
  static const style = Tr('শেখার ধরন', 'Learning style');
  static const styleVisual = Tr('চিত্র ও উদাহরণ', 'Diagrams & examples');
  static const styleText = Tr('লেখা ও নোট', 'Reading & notes');
  static const stylePractice = Tr('অনুশীলন', 'Practice first');
  static const difficulty = Tr('প্রশ্নের কঠিনতা', 'Question difficulty');
  static const adaptive = Tr('অ্যাডাপটিভ', 'Adaptive');
  static const easier = Tr('সহজ দিয়ে শুরু', 'Start easier');
  static const harder = Tr('চ্যালেঞ্জিং', 'Challenging');
  static const tutor = Tr('AI টিউটর', 'AI tutor');
  static const tutorMode = Tr('ডিফল্ট শেখানোর ধরন', 'Default teaching mode');
  static const tutorLang = Tr('উত্তরের ভাষা', 'Answer language');
  static const sources = Tr('বইয়ের উৎস দেখাও', 'Show textbook sources');
  static const followUps = Tr('ফলো-আপ প্রশ্নের পরামর্শ', 'Suggest follow-up questions');
  static const voice = Tr('ভয়েস', 'Voice');
  static const voiceType = Tr('কণ্ঠ', 'Voice');
  static const female = Tr('নারী', 'Female');
  static const male = Tr('পুরুষ', 'Male');
  static const speed = Tr('কথার গতি', 'Speaking speed');
  static const handsFree = Tr('হ্যান্ডস-ফ্রি দিয়ে শুরু', 'Start in hands-free mode');
  static const autoplay = Tr('উত্তর নিজে থেকে পড়ে শোনাও', 'Read answers aloud automatically');
  static const security = Tr('নিরাপত্তা', 'Security');
  static const changePassword = Tr('পাসওয়ার্ড পরিবর্তন', 'Change password');
  static const current = Tr('বর্তমান পাসওয়ার্ড', 'Current password');
  static const newPassword = Tr('নতুন পাসওয়ার্ড (৮+ অক্ষর)', 'New password (8+ characters)');
  static const passwordChanged = Tr('পাসওয়ার্ড পরিবর্তন হয়েছে (ডেমো)', 'Password changed (demo)');
  static const passwordShort = Tr('নতুন পাসওয়ার্ড অন্তত ৮ অক্ষরের হতে হবে', 'The new password needs at least 8 characters');
  static const twoStep = Tr('দুই-ধাপে যাচাই (OTP)', 'Two-step verification (OTP)');
  static const twoStepHint = Tr('নতুন ডিভাইসে লগইন করলে ফোনে কোড যাবে', 'A code is sent to your phone when you sign in on a new device');
  static const sessions = Tr('সক্রিয় সেশন', 'Active sessions');
  static const thisDevice = Tr('এই ডিভাইস', 'This device');
  static const signOutOthers = Tr('অন্য সব ডিভাইস থেকে সাইন আউট', 'Sign out of all other devices');
  static const signedOut = Tr('অন্য ডিভাইস থেকে সাইন আউট হয়েছে', 'Signed out of other devices');
  static const loginAlerts = Tr('নতুন লগইনে সতর্কবার্তা', 'Alerts on new sign-ins');
  static const photo = Tr('প্রোফাইল ছবি', 'Profile photo');
  static const changePhoto = Tr('ছবি বদলাও', 'Change photo');
  static const removePhoto = Tr('ছবি সরাও', 'Remove photo');
  static const prefsTitle = Tr('পছন্দ', 'Preferences');
}

enum LearningStyle { visual, text, practice }

enum DifficultyPref { adaptive, easier, harder }

class SessionInfo {
  const SessionInfo(this.id, this.device, this.place, this.lastActive, {this.current = false});

  factory SessionInfo.fromJson(Map<String, dynamic> j) => SessionInfo(j['id'] as String, j['device'] as String, j['place'] as String, DateTime.parse(j['lastActive'] as String), current: j['current'] as bool? ?? false);

  final String id;
  final String device;
  final String place;
  final DateTime lastActive;
  final bool current;

  Map<String, dynamic> toJson() => {'id': id, 'device': device, 'place': place, 'lastActive': lastActive.toIso8601String(), 'current': current};
}

/// Personal learning, tutor, voice and security preferences (web SET-03, SET-07, SET-08, SET-13).
class LearningPrefs {
  const LearningPrefs({
    this.style = LearningStyle.visual,
    this.difficulty = DifficultyPref.adaptive,
    this.tutorMode = TeachingMode.simple,
    this.tutorLanguage = TutorLanguage.bn,
    this.showSources = true,
    this.followUps = true,
    this.voiceMale = false,
    this.voiceRate = 1,
    this.handsFree = true,
    this.autoplay = true,
    this.twoStep = false,
    this.loginAlerts = true,
    this.avatarPath,
    this.passwordChangedAt,
    this.sessions = const [],
  });

  factory LearningPrefs.fromJson(Map<String, dynamic> j) => LearningPrefs(
    style: LearningStyle.values.byName(j['style'] as String? ?? 'visual'),
    difficulty: DifficultyPref.values.byName(j['difficulty'] as String? ?? 'adaptive'),
    tutorMode: TeachingMode.values.byName(j['tutorMode'] as String? ?? 'simple'),
    tutorLanguage: TutorLanguage.values.byName(j['tutorLanguage'] as String? ?? 'bn'),
    showSources: j['showSources'] as bool? ?? true,
    followUps: j['followUps'] as bool? ?? true,
    voiceMale: j['voiceMale'] as bool? ?? false,
    voiceRate: (j['voiceRate'] as num?)?.toDouble() ?? 1,
    handsFree: j['handsFree'] as bool? ?? true,
    autoplay: j['autoplay'] as bool? ?? true,
    twoStep: j['twoStep'] as bool? ?? false,
    loginAlerts: j['loginAlerts'] as bool? ?? true,
    avatarPath: j['avatarPath'] as String?,
    passwordChangedAt: j['passwordChangedAt'] == null ? null : DateTime.parse(j['passwordChangedAt'] as String),
    sessions: [for (final s in j['sessions'] as List? ?? const []) SessionInfo.fromJson((s as Map).cast())],
  );

  final LearningStyle style;
  final DifficultyPref difficulty;
  final TeachingMode tutorMode;
  final TutorLanguage tutorLanguage;
  final bool showSources;
  final bool followUps;
  final bool voiceMale;
  final double voiceRate;
  final bool handsFree;
  final bool autoplay;
  final bool twoStep;
  final bool loginAlerts;

  /// Local path of the chosen profile photo (AUTH-14).
  final String? avatarPath;
  final DateTime? passwordChangedAt;
  final List<SessionInfo> sessions;

  LearningPrefs copyWith({
    LearningStyle? style,
    DifficultyPref? difficulty,
    TeachingMode? tutorMode,
    TutorLanguage? tutorLanguage,
    bool? showSources,
    bool? followUps,
    bool? voiceMale,
    double? voiceRate,
    bool? handsFree,
    bool? autoplay,
    bool? twoStep,
    bool? loginAlerts,
    String? Function()? avatarPath,
    DateTime? passwordChangedAt,
    List<SessionInfo>? sessions,
  }) => LearningPrefs(
    style: style ?? this.style,
    difficulty: difficulty ?? this.difficulty,
    tutorMode: tutorMode ?? this.tutorMode,
    tutorLanguage: tutorLanguage ?? this.tutorLanguage,
    showSources: showSources ?? this.showSources,
    followUps: followUps ?? this.followUps,
    voiceMale: voiceMale ?? this.voiceMale,
    voiceRate: voiceRate ?? this.voiceRate,
    handsFree: handsFree ?? this.handsFree,
    autoplay: autoplay ?? this.autoplay,
    twoStep: twoStep ?? this.twoStep,
    loginAlerts: loginAlerts ?? this.loginAlerts,
    avatarPath: avatarPath == null ? this.avatarPath : avatarPath(),
    passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
    sessions: sessions ?? this.sessions,
  );

  Map<String, dynamic> toJson() => {
    'style': style.name,
    'difficulty': difficulty.name,
    'tutorMode': tutorMode.name,
    'tutorLanguage': tutorLanguage.name,
    'showSources': showSources,
    'followUps': followUps,
    'voiceMale': voiceMale,
    'voiceRate': voiceRate,
    'handsFree': handsFree,
    'autoplay': autoplay,
    'twoStep': twoStep,
    'loginAlerts': loginAlerts,
    'avatarPath': avatarPath,
    'passwordChangedAt': passwordChangedAt?.toIso8601String(),
    'sessions': [for (final s in sessions) s.toJson()],
  };
}

class LearningPrefsController extends Notifier<LearningPrefs> {
  static const _col = 'learningPrefs';
  late LocalStore _store;

  @override
  LearningPrefs build() {
    _store = watchStore(ref);
    final j = _store.get(_col, 'me');
    if (j != null) return LearningPrefs.fromJson(j);
    final now = DateTime.now();
    return LearningPrefs(sessions: [
      SessionInfo('s-this', 'এই ফোন (Android)', 'ঢাকা', now, current: true),
      SessionInfo('s-web', 'Chrome · Windows', 'ঢাকা', now.subtract(const Duration(days: 1, hours: 3))),
      SessionInfo('s-tab', 'ট্যাবলেট (Android)', 'চট্টগ্রাম', now.subtract(const Duration(days: 6))),
    ]);
  }

  Future<void> update(LearningPrefs Function(LearningPrefs p) change) async {
    state = change(state);
    await _store.put(_col, 'me', state.toJson());
  }

  Future<void> changePassword(String current, String next) async {
    await ref.read(mockSimulatorProvider).run(() {});
    if (current.isEmpty) throw const ApiException(statusCode: 400, code: 'INVALID', message: 'বর্তমান পাসওয়ার্ড দিন');
    if (next.length < 8) throw const ApiException(statusCode: 400, code: 'WEAK_PASSWORD', message: 'নতুন পাসওয়ার্ড অন্তত ৮ অক্ষরের হতে হবে');
    await update((p) => p.copyWith(passwordChangedAt: DateTime.now()));
  }

  Future<void> signOutOthers() async {
    await ref.read(mockSimulatorProvider).run(() {});
    await update((p) => p.copyWith(sessions: [for (final s in p.sessions) if (s.current) s]));
  }
}

final learningPrefsProvider = NotifierProvider<LearningPrefsController, LearningPrefs>(LearningPrefsController.new);

/// Profile photo with change/remove (AUTH-14).
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, this.radius = 24, this.editable = false});

  final double radius;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(learningPrefsProvider.select((p) => p.avatarPath));
    final hasFile = path != null && File(path).existsSync();
    final avatar = CircleAvatar(radius: radius, backgroundImage: hasFile ? FileImage(File(path)) : null, child: hasFile ? null : Icon(Icons.person_outline, size: radius));
    if (!editable) return avatar;
    return Column(
      children: [
        avatar,
        Wrap(
          children: [
            TextButton(
              key: const Key('avatar.change'),
              onPressed: () async {
                try {
                  final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
                  if (f != null) await ref.read(learningPrefsProvider.notifier).update((p) => p.copyWith(avatarPath: () => f.path));
                } on Object {
                  // Picker unavailable (tests/simulator).
                }
              },
              child: Text(context.tr(PrefStrings.changePhoto)),
            ),
            if (path != null) TextButton(onPressed: () => ref.read(learningPrefsProvider.notifier).update((p) => p.copyWith(avatarPath: () => null)), child: Text(context.tr(PrefStrings.removePhoto))),
          ],
        ),
      ],
    );
  }
}

/// Learning, AI tutor and voice preferences.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningPrefsProvider);
    final c = ref.read(learningPrefsProvider.notifier);
    return AppPageScaffold(
      title: context.tr(PrefStrings.prefsTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(PrefStrings.learning)),
          Text(context.tr(PrefStrings.style), style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final (s, l) in [(LearningStyle.visual, PrefStrings.styleVisual), (LearningStyle.text, PrefStrings.styleText), (LearningStyle.practice, PrefStrings.stylePractice)])
                ChoiceChip(label: Text(context.tr(l)), selected: p.style == s, onSelected: (_) => c.update((x) => x.copyWith(style: s))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr(PrefStrings.difficulty), style: Theme.of(context).textTheme.labelLarge),
          SegmentedButton<DifficultyPref>(
            segments: [
              ButtonSegment(value: DifficultyPref.easier, label: Text(context.tr(PrefStrings.easier))),
              ButtonSegment(value: DifficultyPref.adaptive, label: Text(context.tr(PrefStrings.adaptive))),
              ButtonSegment(value: DifficultyPref.harder, label: Text(context.tr(PrefStrings.harder))),
            ],
            selected: {p.difficulty},
            onSelectionChanged: (v) => c.update((x) => x.copyWith(difficulty: v.first)),
          ),
          SectionHeader(title: context.tr(PrefStrings.tutor)),
          DropdownButtonFormField<TeachingMode>(
            key: const Key('prefs.tutorMode'),
            isExpanded: true,
            initialValue: p.tutorMode,
            decoration: InputDecoration(labelText: context.tr(PrefStrings.tutorMode)),
            items: [for (final m in TeachingMode.values) DropdownMenuItem(value: m, child: Text(context.tr(m.label)))],
            onChanged: (v) => c.update((x) => x.copyWith(tutorMode: v)),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<TutorLanguage>(
            isExpanded: true,
            initialValue: p.tutorLanguage,
            decoration: InputDecoration(labelText: context.tr(PrefStrings.tutorLang)),
            items: [for (final l in TutorLanguage.values) DropdownMenuItem(value: l, child: Text(context.tr(l.label)))],
            onChanged: (v) => c.update((x) => x.copyWith(tutorLanguage: v)),
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(PrefStrings.sources)), value: p.showSources, onChanged: (v) => c.update((x) => x.copyWith(showSources: v))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(PrefStrings.followUps)), value: p.followUps, onChanged: (v) => c.update((x) => x.copyWith(followUps: v))),
          SectionHeader(title: context.tr(PrefStrings.voice)),
          SegmentedButton<bool>(
            segments: [ButtonSegment(value: false, label: Text(context.tr(PrefStrings.female))), ButtonSegment(value: true, label: Text(context.tr(PrefStrings.male)))],
            selected: {p.voiceMale},
            onSelectionChanged: (v) => c.update((x) => x.copyWith(voiceMale: v.first)),
          ),
          Row(
            children: [
              Text('${context.tr(PrefStrings.speed)}: ${p.voiceRate.toStringAsFixed(2)}×'),
              Expanded(child: Slider(key: const Key('prefs.voiceRate'), value: p.voiceRate, min: 0.5, max: 1.5, divisions: 4, onChanged: (v) => c.update((x) => x.copyWith(voiceRate: v)))),
            ],
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(PrefStrings.handsFree)), value: p.handsFree, onChanged: (v) => c.update((x) => x.copyWith(handsFree: v))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(PrefStrings.autoplay)), value: p.autoplay, onChanged: (v) => c.update((x) => x.copyWith(autoplay: v))),
        ],
      ),
    );
  }
}

/// Security settings (SET-13): password, two-step verification, sessions, alerts.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(learningPrefsProvider);
    final c = ref.read(learningPrefsProvider.notifier);
    return AppPageScaffold(
      title: context.tr(PrefStrings.security),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(PrefStrings.changePassword)),
          TextField(key: const Key('sec.current'), controller: _current, obscureText: true, decoration: InputDecoration(labelText: context.tr(PrefStrings.current))),
          const SizedBox(height: AppSpacing.sm),
          TextField(key: const Key('sec.next'), controller: _next, obscureText: true, decoration: InputDecoration(labelText: context.tr(PrefStrings.newPassword))),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('sec.save'),
            onPressed: () async {
              try {
                await c.changePassword(_current.text, _next.text);
                _current.clear();
                _next.clear();
                if (context.mounted) context.showSnack(PrefStrings.passwordChanged);
              } on ApiException catch (e) {
                if (context.mounted) context.showErrorSnack(e);
              }
            },
            child: Text(context.tr(S.save)),
          ),
          if (p.passwordChangedAt != null) Text(relativeTime(p.passwordChangedAt!, context.lang), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(key: const Key('sec.twoStep'), contentPadding: EdgeInsets.zero, title: Text(context.tr(PrefStrings.twoStep)), subtitle: Text(context.tr(PrefStrings.twoStepHint)), value: p.twoStep, onChanged: (v) => c.update((x) => x.copyWith(twoStep: v))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(PrefStrings.loginAlerts)), value: p.loginAlerts, onChanged: (v) => c.update((x) => x.copyWith(loginAlerts: v))),
          SectionHeader(title: context.tr(PrefStrings.sessions)),
          for (final s in p.sessions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(s.device.contains('Chrome') ? Icons.laptop : Icons.phone_android),
              title: Text(s.device),
              subtitle: Text('${s.place} · ${relativeTime(s.lastActive, context.lang)}'),
              trailing: s.current ? Pill(context.tr(PrefStrings.thisDevice), tone: Tone.success) : null,
            ),
          if (p.sessions.length > 1)
            OutlinedButton.icon(
              key: const Key('sec.signOutOthers'),
              onPressed: () async {
                await c.signOutOthers();
                if (context.mounted) context.showSnack(PrefStrings.signedOut);
              },
              icon: const Icon(Icons.logout),
              label: Text(context.tr(PrefStrings.signOutOthers)),
            ),
        ],
      ),
    );
  }
}

/// Settings entries for the extra preference screens.
class PreferenceLinks extends StatelessWidget {
  const PreferenceLinks({super.key, this.student = true});

  final bool student;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        if (student)
          ListTile(
            key: const Key('settings.prefs'),
            leading: const Icon(Icons.tune),
            title: Text(context.tr(PrefStrings.prefsTitle)),
            subtitle: Text('${context.tr(PrefStrings.learning)} · ${context.tr(PrefStrings.tutor)} · ${context.tr(PrefStrings.voice)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PreferencesScreen())),
          ),
        ListTile(
          key: const Key('settings.notifications'),
          leading: const Icon(Icons.notifications_outlined),
          title: Text(context.tr(const Tr('নোটিফিকেশন পছন্দ', 'Notification preferences'))),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.notificationPrefs),
        ),
        ListTile(
          key: const Key('settings.security'),
          leading: const Icon(Icons.lock_outline),
          title: Text(context.tr(PrefStrings.security)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SecurityScreen())),
        ),
      ],
    ),
  );
}
