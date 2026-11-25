import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../../../shared/widgets/feedback.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../profile/application/student_profile_controller.dart';
import '../application/auth_controller.dart';
import '../domain/app_user.dart';

abstract final class AuthFlowStrings {
  static const welcome1 = Tr('প্রত্যেক শিক্ষার্থীর জন্য একজন ব্যক্তিগত AI শিক্ষক', 'A personal AI teacher for every student');
  static const welcome1b = Tr('পাঠ্যবইভিত্তিক উত্তর, পৃষ্ঠা নম্বরসহ।', 'Textbook-based answers, with page numbers.');
  static const welcome2 = Tr('প্রতিটি বইয়ের নিজস্ব অ্যাভাটার শিক্ষক', 'Every book has its own avatar teacher');
  static const welcome2b = Tr('লিখে বা কথা বলে প্রশ্ন করো — শিক্ষক মুখে উত্তর দেবেন।', 'Ask by typing or speaking — the teacher answers aloud.');
  static const welcome3 = Tr('বোর্ড প্রস্তুতি, পরীক্ষা ও অগ্রগতি এক জায়গায়', 'Board prep, exams and progress in one place');
  static const welcome3b = Tr('দুর্বলতা ধরে নিজের মতো পরিকল্পনা।', 'A plan built around your weak areas.');
  static const start = Tr('শুরু করো', 'Get started');
  static const haveAccount = Tr('আগে থেকেই অ্যাকাউন্ট আছে? লগইন', 'Already have an account? Log in');
  static const register = Tr('নতুন অ্যাকাউন্ট খুলুন', 'Create an account');
  static const iAm = Tr('আমি একজন', 'I am a');
  static const student = Tr('শিক্ষার্থী', 'Student');
  static const parent = Tr('অভিভাবক', 'Parent');
  static const teacherNote = Tr('শিক্ষকের অ্যাকাউন্ট আমন্ত্রণের মাধ্যমে তৈরি হয়।', 'Teacher accounts are created by invitation.');
  static const name = Tr('নাম', 'Name');
  static const identifier = Tr('মোবাইল নম্বর বা ইমেইল', 'Mobile number or email');
  static const password = Tr('পাসওয়ার্ড', 'Password');
  static const confirm = Tr('পাসওয়ার্ড নিশ্চিত করুন', 'Confirm password');
  static const terms = Tr('আমি শর্তাবলি ও গোপনীয়তা নীতিতে সম্মত', 'I agree to the terms and privacy policy');
  static const next = Tr('পরবর্তী', 'Next');
  static const back = Tr('আগের', 'Back');
  static const nameError = Tr('নাম লিখুন', 'Enter your name');
  static const idError = Tr('সঠিক মোবাইল (01XXXXXXXXX) বা ইমেইল দিন', 'Enter a valid mobile (01XXXXXXXXX) or email');
  static const pwError = Tr('কমপক্ষে ৮ অক্ষর, অক্ষর ও সংখ্যা মিলিয়ে', 'At least 8 characters with letters and numbers');
  static const matchError = Tr('পাসওয়ার্ড মেলেনি', 'Passwords do not match');
  static const termsError = Tr('শর্তাবলিতে সম্মতি দিন', 'Please accept the terms');
  static const otpTitle = Tr('যাচাই কোড দিন', 'Enter the verification code');
  static const otpHint = Tr('{id}-এ ৬ অঙ্কের কোড পাঠানো হয়েছে (ডেমো কোড: 123456)', 'A 6-digit code was sent to {id} (demo code: 123456)');
  static const verify = Tr('যাচাই করুন', 'Verify');
  static const wrongOtp = Tr('কোড সঠিক নয়', 'Incorrect code');
  static const resend = Tr('আবার পাঠাও', 'Resend');
  static const resendIn = Tr('{n} সেকেন্ড পর আবার পাঠানো যাবে', 'Resend in {n} s');
  static const resent = Tr('নতুন কোড পাঠানো হয়েছে', 'A new code was sent');
  static const noPending = Tr('যাচাইয়ের অনুরোধ পাওয়া যায়নি। আবার লগইন বা নিবন্ধন করুন।', 'No verification in progress. Please log in or register again.');
  static const forgot = Tr('পাসওয়ার্ড ভুলে গেছেন?', 'Forgot password?');
  static const forgotHint = Tr('অ্যাকাউন্টের মোবাইল বা ইমেইল দিন — যাচাই কোড পাঠানো হবে।', 'Enter your account mobile or email — we will send a code.');
  static const sendCode = Tr('কোড পাঠাও', 'Send code');
  static const newPassword = Tr('নতুন পাসওয়ার্ড', 'New password');
  static const resetDone = Tr('পাসওয়ার্ড বদলানো হয়েছে — নতুন পাসওয়ার্ডে লগইন করুন', 'Password changed — log in with the new password');
  static const save = Tr('সংরক্ষণ', 'Save');
  // Onboarding
  static const obTitle = Tr('তোমার প্রোফাইল সাজাই', "Let's set up your profile");
  static const step = Tr('ধাপ {n} / {t}', 'Step {n} / {t}');
  static const obBasics = Tr('পরিচয়', 'About you');
  static const obAcademic = Tr('একাডেমিক তথ্য', 'Academic details');
  static const obSubjects = Tr('কোন বিষয়ে বেশি সাহায্য চাও?', 'Which subjects need more help?');
  static const obGoals = Tr('লক্ষ্য', 'Goals');
  static const obSchedule = Tr('পড়ার সময়', 'Study time');
  static const obReview = Tr('পর্যালোচনা', 'Review');
  static const level = Tr('স্তর', 'Level');
  static const classYear = Tr('শ্রেণি', 'Class');
  static const group = Tr('বিভাগ', 'Group');
  static const board = Tr('বোর্ড', 'Board');
  static const school = Tr('স্কুল / কলেজের নাম (ঐচ্ছিক)', 'School / college name (optional)');
  static const targetGpa = Tr('লক্ষ্য GPA: {g}', 'Target GPA: {g}');
  static const examYear = Tr('পরীক্ষার বছর', 'Exam year');
  static const daily = Tr('প্রতিদিন {n} মিনিট', '{n} minutes a day');
  static const finish = Tr('শেষ করুন', 'Finish');
  static const ready = Tr('সব প্রস্তুত! তোমার ব্যক্তিগত পরিকল্পনা তৈরি হয়েছে।', 'All set! Your personal plan is ready.');
}

/// What is being verified with the OTP.
enum OtpPurpose { register, reset }

class PendingAuth {
  const PendingAuth({required this.purpose, required this.identifier, this.name = '', this.password = '', this.role = UserRole.student});

  final OtpPurpose purpose;
  final String identifier;
  final String name;
  final String password;
  final UserRole role;
}

class PendingAuthController extends Notifier<PendingAuth?> {
  @override
  PendingAuth? build() => null;

  // ignore: use_setters_to_change_properties
  void set(PendingAuth? value) => state = value;
}

final pendingAuthProvider = NotifierProvider<PendingAuthController, PendingAuth?>(PendingAuthController.new);

final _phone = RegExp(r'^01[3-9]\d{8}$');
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool validIdentifier(String v) => _phone.hasMatch(v.trim()) || _email.hasMatch(v.trim());
bool strongPassword(String v) => v.length >= 8 && RegExp('[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v);

Widget _authShell(BuildContext context, {required String title, required List<Widget> children, bool back = true}) => Scaffold(
  appBar: back ? AppBar() : null,
  body: SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: AppSpacing.lg), ...children],
          ),
        ),
      ),
    ),
  ),
);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const slides = [
      (Icons.smart_toy_outlined, AuthFlowStrings.welcome1, AuthFlowStrings.welcome1b),
      (Icons.co_present_outlined, AuthFlowStrings.welcome2, AuthFlowStrings.welcome2b),
      (Icons.insights_outlined, AuthFlowStrings.welcome3, AuthFlowStrings.welcome3b),
    ];
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _i = i),
                  children: [
                    for (final (icon, title, body) in slides)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 96, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: AppSpacing.xl),
                          Text(context.tr(title), textAlign: TextAlign.center, style: text.headlineSmall),
                          const SizedBox(height: AppSpacing.sm),
                          Text(context.tr(body), textAlign: TextAlign.center, style: text.bodyLarge),
                        ],
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var k = 0; k < 3; k++)
                    Container(
                      width: k == _i ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: k == _i ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(key: const Key('welcome.start'), onPressed: () => context.go(AppRoutes.register), child: Text(context.tr(AuthFlowStrings.start))),
              TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(context.tr(AuthFlowStrings.haveAccount))),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  UserRole _role = UserRole.student;
  bool _terms = false;
  bool _termsError = false;

  @override
  void dispose() {
    for (final c in [_name, _id, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _authShell(
      context,
      title: context.tr(AuthFlowStrings.register),
      children: [
        Text(context.tr(AuthFlowStrings.iAm)),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<UserRole>(
          segments: [
            ButtonSegment(value: UserRole.student, label: Text(context.tr(AuthFlowStrings.student)), icon: const Icon(Icons.school_outlined)),
            ButtonSegment(value: UserRole.parent, label: Text(context.tr(AuthFlowStrings.parent)), icon: const Icon(Icons.family_restroom_outlined)),
          ],
          selected: {_role},
          onSelectionChanged: (v) => setState(() => _role = v.first),
        ),
        Text(context.tr(AuthFlowStrings.teacherNote), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(key: const Key('reg.name'), controller: _name, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.name)), validator: (v) => (v ?? '').trim().length < 2 ? context.tr(AuthFlowStrings.nameError) : null),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(key: const Key('reg.id'), controller: _id, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.identifier)), validator: (v) => validIdentifier(v ?? '') ? null : context.tr(AuthFlowStrings.idError)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(key: const Key('reg.pw'), controller: _pw, obscureText: true, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.password)), validator: (v) => strongPassword(v ?? '') ? null : context.tr(AuthFlowStrings.pwError)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(key: const Key('reg.pw2'), controller: _pw2, obscureText: true, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.confirm)), validator: (v) => v == _pw.text ? null : context.tr(AuthFlowStrings.matchError)),
            ],
          ),
        ),
        CheckboxListTile(
          key: const Key('reg.terms'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _terms,
          onChanged: (v) => setState(() {
            _terms = v ?? false;
            _termsError = false;
          }),
          title: Text(context.tr(AuthFlowStrings.terms)),
          subtitle: _termsError ? Text(context.tr(AuthFlowStrings.termsError), style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('reg.submit'),
          onPressed: () {
            final ok = _form.currentState?.validate() ?? false;
            setState(() => _termsError = !_terms);
            if (!ok || !_terms) return;
            ref.read(pendingAuthProvider.notifier).set(PendingAuth(purpose: OtpPurpose.register, identifier: _id.text.trim(), name: _name.text.trim(), password: _pw.text, role: _role));
            context.go(AppRoutes.verifyOtp);
          },
          child: Text(context.tr(AuthFlowStrings.next)),
        ),
        TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(context.tr(AuthFlowStrings.haveAccount))),
      ],
    );
  }
}

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;
  int _wait = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _wait = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify(PendingAuth p) async {
    if (_code.text.trim() != '123456') return setState(() => _error = context.tr(AuthFlowStrings.wrongOtp));
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (p.purpose == OtpPurpose.reset) {
        if (mounted) context.go(AppRoutes.resetPassword);
        return;
      }
      await ref.read(authControllerProvider.notifier).register(name: p.name, identifier: p.identifier, password: p.password, role: p.role);
      ref.read(pendingAuthProvider.notifier).set(null);
      if (p.role == UserRole.student) {
        await ref.read(studentProfileProvider.notifier).update((s) => s.copyWith(name: p.name, onboarded: false));
      }
      if (!mounted) return;
      context.go(AppRoutes.consent);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(pendingAuthProvider);
    if (p == null) {
      return _authShell(context, title: context.tr(AuthFlowStrings.otpTitle), children: [Text(context.tr(AuthFlowStrings.noPending)), TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(context.tr(AuthFlowStrings.haveAccount)))]);
    }
    return _authShell(
      context,
      title: context.tr(AuthFlowStrings.otpTitle),
      children: [
        Text(context.tr(AuthFlowStrings.otpHint.fill({'id': p.identifier}))),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('otp.code'),
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 12),
          decoration: InputDecoration(errorText: _error, counterText: ''),
          onSubmitted: (_) => _verify(p),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(key: const Key('otp.verify'), onPressed: _busy ? null : () => _verify(p), child: Text(context.tr(AuthFlowStrings.verify))),
        TextButton(
          onPressed: _wait > 0
              ? null
              : () {
                  _startTimer();
                  context.showSnack(AuthFlowStrings.resent);
                },
          child: Text(_wait > 0 ? context.tr(AuthFlowStrings.resendIn.fill({'n': _wait})) : context.tr(AuthFlowStrings.resend)),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _id = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _authShell(
    context,
    title: context.tr(AuthFlowStrings.forgot),
    children: [
      Text(context.tr(AuthFlowStrings.forgotHint)),
      const SizedBox(height: AppSpacing.md),
      TextField(key: const Key('forgot.id'), controller: _id, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.identifier), errorText: _error)),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        key: const Key('forgot.send'),
        onPressed: () {
          if (!validIdentifier(_id.text)) return setState(() => _error = context.tr(AuthFlowStrings.idError));
          ref.read(pendingAuthProvider.notifier).set(PendingAuth(purpose: OtpPurpose.reset, identifier: _id.text.trim()));
          context.go(AppRoutes.verifyOtp);
        },
        child: Text(context.tr(AuthFlowStrings.sendCode)),
      ),
    ],
  );
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _authShell(
    context,
    title: context.tr(AuthFlowStrings.newPassword),
    children: [
      TextField(key: const Key('reset.pw'), controller: _pw, obscureText: true, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.newPassword), errorText: _error)),
      const SizedBox(height: AppSpacing.sm),
      TextField(key: const Key('reset.pw2'), controller: _pw2, obscureText: true, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.confirm))),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        key: const Key('reset.save'),
        onPressed: () {
          if (!strongPassword(_pw.text)) return setState(() => _error = context.tr(AuthFlowStrings.pwError));
          if (_pw.text != _pw2.text) return setState(() => _error = context.tr(AuthFlowStrings.matchError));
          ref.read(pendingAuthProvider.notifier).set(null);
          context.showSnack(AuthFlowStrings.resetDone);
          context.go(AppRoutes.login);
        },
        child: Text(context.tr(AuthFlowStrings.save)),
      ),
    ],
  );
}

/// Student onboarding (6 steps + review); saves the academic profile.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late var _p = ref.read(studentProfileProvider);
  late final _name = TextEditingController(text: _p.name);
  late final _school = TextEditingController(text: _p.institution);
  int _step = 0;
  static const _steps = [AuthFlowStrings.obBasics, AuthFlowStrings.obAcademic, AuthFlowStrings.obSubjects, AuthFlowStrings.obGoals, AuthFlowStrings.obSchedule, AuthFlowStrings.obReview];

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    super.dispose();
  }

  Widget _body(BuildContext context) {
    final text = Theme.of(context).textTheme;
    switch (_step) {
      case 0:
        return Column(children: [
          TextField(key: const Key('ob.name'), controller: _name, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.name))),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _school, decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.school))),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<EducationLevel>(
            segments: [for (final l in EducationLevel.values) ButtonSegment(value: l, label: Text(context.tr(l.label)))],
            selected: {_p.level},
            onSelectionChanged: (v) => setState(() => _p = _p.copyWith(level: v.first, classYear: v.first.classes.last)),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<AcademicGroup>(
            isExpanded: true,
            initialValue: _p.group,
            decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.group)),
            items: [for (final g in AcademicGroup.values) DropdownMenuItem(value: g, child: Text(context.tr(g.label)))],
            onChanged: (v) => setState(() => _p = _p.copyWith(group: v)),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _p.boardId,
            decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.board)),
            items: [for (final b in educationBoards) DropdownMenuItem(value: b.id, child: Text(context.tr(b.name)))],
            onChanged: (v) => setState(() => _p = _p.copyWith(boardId: v)),
          ),
        ]);
      case 2:
        final subjects = [for (final s in seedSubjects) if (s.level == _p.level && s.availableFor(_p.group)) s];
        return Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
          for (final s in subjects)
            FilterChip(
              label: Text(context.tr(s.name)),
              selected: _p.weakSubjectIds.contains(s.id),
              onSelected: (on) => setState(() => _p = _p.copyWith(weakSubjectIds: on ? [..._p.weakSubjectIds, s.id] : [for (final x in _p.weakSubjectIds) if (x != s.id) x])),
            ),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.tr(AuthFlowStrings.targetGpa.fill({'g': _p.targetGpa.toStringAsFixed(2)}))),
          Slider(value: _p.targetGpa, min: 3, max: 5, divisions: 8, onChanged: (v) => setState(() => _p = _p.copyWith(targetGpa: v))),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _p.examYear,
            decoration: InputDecoration(labelText: context.tr(AuthFlowStrings.examYear)),
            items: [for (var y = 2026; y <= 2030; y++) DropdownMenuItem(value: y, child: Text(context.n(y)))],
            onChanged: (v) => setState(() => _p = _p.copyWith(examYear: v)),
          ),
        ]);
      case 4:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.tr(AuthFlowStrings.daily.fill({'n': _p.dailyMinutes})), style: text.titleMedium),
          Slider(value: _p.dailyMinutes.toDouble(), min: 15, max: 240, divisions: 15, onChanged: (v) => setState(() => _p = _p.copyWith(dailyMinutes: v.round()))),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_name.text, style: text.titleMedium),
          Text('${context.tr(_p.level.label)} · ${context.n(_p.classYear)} · ${context.tr(_p.group.label)}'),
          Text(context.tr(AuthFlowStrings.targetGpa.fill({'g': _p.targetGpa.toStringAsFixed(2)}))),
          Text(context.tr(AuthFlowStrings.daily.fill({'n': _p.dailyMinutes}))),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _steps.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AuthFlowStrings.obTitle))),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Text(context.tr(AuthFlowStrings.step.fill({'n': _step + 1, 't': _steps.length}))),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: (_step + 1) / _steps.length),
            const SizedBox(height: AppSpacing.lg),
            Text(context.tr(_steps[_step]), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _body(context),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (_step > 0) OutlinedButton(onPressed: () => setState(() => _step--), child: Text(context.tr(AuthFlowStrings.back))),
                const Spacer(),
                FilledButton(
                  key: const Key('ob.next'),
                  onPressed: () async {
                    if (!last) return setState(() => _step++);
                    await ref.read(studentProfileProvider.notifier).update((_) => _p.copyWith(name: _name.text.trim(), institution: _school.text.trim(), onboarded: true));
                    if (!context.mounted) return;
                    context.showSnack(AuthFlowStrings.ready);
                    context.go(AppRoutes.portalHome(UserRole.student));
                  },
                  child: Text(context.tr(last ? AuthFlowStrings.finish : AuthFlowStrings.next)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class ConsentStrings {
  static const title = Tr('গোপনীয়তা ও সম্মতি', 'Privacy & consent');
  static const intro = Tr('শুরু করার আগে জেনে নাও আমরা তোমার তথ্য কীভাবে ব্যবহার করি। যেকোনো বয়সের শিক্ষার্থী নিজেই অ্যাকাউন্ট খুলতে পারে।', 'Before you start, see how we use your data. Students of any age can create their own account.');
  static const p1 = Tr('তোমার পড়াশোনার তথ্য শুধু শেখানো ও অগ্রগতি দেখানোর জন্য ব্যবহার হয়। আমরা তথ্য বিক্রি করি না।', 'Your learning data is used only to teach you and show progress. We never sell data.');
  static const p2 = Tr('AI কথোপকথন ব্যক্তিগত — অভিভাবক বা শিক্ষক দেখতে পান না, যদি না তুমি নিজে শেয়ার করো।', 'AI conversations are private — guardians and teachers cannot see them unless you share them.');
  static const p3 = Tr('AI-এর উত্তর ভুল হতে পারে; বইয়ের উৎস দেখে মিলিয়ে নাও। নম্বর AI-এর আনুমানিক, চূড়ান্ত নয়।', 'AI answers can be wrong; check the textbook sources. Marks from AI are estimates, not final.');
  static const p4 = Tr('তুমি যেকোনো সময় তথ্য ডাউনলোড বা অ্যাকাউন্ট মুছে ফেলার অনুরোধ করতে পারো।', 'You can download your data or ask to delete your account at any time.');
  static const terms = Tr('শর্তাবলি ও গোপনীয়তা নীতি পড়েছি এবং মেনে নিচ্ছি', 'I have read and accept the terms and privacy policy');
  static const ai = Tr('বুঝেছি যে AI-এর উত্তর ও নম্বর আনুমানিক', 'I understand AI answers and marks are estimates');
  static const updates = Tr('পড়ার টিপস ও নতুন ফিচারের খবর পেতে চাই (ঐচ্ছিক)', 'Send me study tips and feature news (optional)');
  static const accept = Tr('সম্মতি দিয়ে এগিয়ে যাও', 'Agree and continue');
}

/// Privacy notice and consent after signup (AUTH-16). No guardian consent step.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _terms = false;
  bool _ai = false;
  bool _updates = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final role = auth is Authenticated ? auth.user.role : UserRole.student;
    return _authShell(
      context,
      title: context.tr(ConsentStrings.title),
      back: false,
      children: [
        Text(context.tr(ConsentStrings.intro)),
        const SizedBox(height: AppSpacing.md),
        for (final (icon, t) in [(Icons.lock_outline, ConsentStrings.p1), (Icons.forum_outlined, ConsentStrings.p2), (Icons.auto_awesome_outlined, ConsentStrings.p3), (Icons.download_outlined, ConsentStrings.p4)])
          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(context.tr(t))),
        CheckboxListTile(key: const Key('consent.terms'), contentPadding: EdgeInsets.zero, value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), title: Text(context.tr(ConsentStrings.terms))),
        CheckboxListTile(key: const Key('consent.ai'), contentPadding: EdgeInsets.zero, value: _ai, onChanged: (v) => setState(() => _ai = v ?? false), title: Text(context.tr(ConsentStrings.ai))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _updates, onChanged: (v) => setState(() => _updates = v ?? false), title: Text(context.tr(ConsentStrings.updates))),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const Key('consent.accept'),
          onPressed: _terms && _ai ? () => context.go(role == UserRole.student ? AppRoutes.onboarding : AppRoutes.portalHome(role)) : null,
          child: Text(context.tr(ConsentStrings.accept)),
        ),
      ],
    );
  }
}

abstract final class ExpiredStrings {
  static const title = Tr('সেশনের মেয়াদ শেষ', 'Session expired');
  static const body = Tr('নিরাপত্তার জন্য তোমাকে সাইন আউট করা হয়েছে। তোমার অফলাইন নোট ও অগ্রগতি এই ডিভাইসে সংরক্ষিত আছে।', 'For your security you were signed out. Your offline notes and progress are still saved on this device.');
  static const again = Tr('আবার লগইন করো', 'Sign in again');
}

/// Shown after a 401 (AUTH-11).
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) => _authShell(
    context,
    title: context.tr(ExpiredStrings.title),
    back: false,
    children: [
      const Icon(Icons.lock_clock_outlined, size: 64),
      const SizedBox(height: AppSpacing.md),
      Text(context.tr(ExpiredStrings.body), textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.lg),
      FilledButton(key: const Key('expired.login'), onPressed: () => context.go(AppRoutes.login), child: Text(context.tr(ExpiredStrings.again))),
    ],
  );
}
