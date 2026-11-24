import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import 'auth_flow_screens.dart';

import '../../../core/config/env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../application/auth_controller.dart';

/// Email/phone + password sign-in. Navigation after success is handled by the router.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(identifier: _identifier.text, password: _password.text);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('লগইন করা যায়নি। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.school, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppConstants.appNameBn,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      AppConstants.tagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      key: const Key('login.identifier'),
                      controller: _identifier,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'ইমেইল বা মোবাইল নম্বর',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.identifier,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const Key('login.password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'পাসওয়ার্ড',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'পাসওয়ার্ড দেখুন' : 'পাসওয়ার্ড লুকান',
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      key: const Key('login.submit'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('লগইন'),
                    ),
                    TextButton(key: const Key('login.forgot'), onPressed: () => context.go(AppRoutes.forgotPassword), child: Text(context.tr(AuthFlowStrings.forgot))),
                    OutlinedButton(key: const Key('login.register'), onPressed: () => context.go(AppRoutes.register), child: Text(context.tr(AuthFlowStrings.register))),
                    if (Env.useMockApi) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'ডেমো মোড: student@…, teacher@… বা parent@… দিয়ে যেকোনো ৮+ অক্ষরের পাসওয়ার্ডে লগইন করুন।',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
