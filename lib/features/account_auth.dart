import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/strings.dart';
import '../core/motion.dart';
import '../core/premium.dart';
import '../core/theme.dart';
import '../services/app_controller.dart';

const authCallback = 'io.daryeel.app://login-callback/';

class AuthFrame extends StatelessWidget {
  final List<Widget> children;
  final bool back;
  final VoidCallback? onBack;
  const AuthFrame({
    super.key,
    required this.children,
    this.back = true,
    this.onBack,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF211B36), const Color(0xFF151322)]
              : [
                  const Color(0xFFF3EAFE),
                  Colors.white,
                  const Color(0xFFF0E9FF),
                ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (back)
                        IconButton(
                          tooltip: tr(context, 'Back'),
                          onPressed: onBack ?? () => context.go('/welcome'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      const Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: SizedBox(
                            width: 220,
                            child: AuthLanguagePicker(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SoftEntrance(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthLanguagePicker extends ConsumerWidget {
  const AuthLanguagePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return DropdownButton<String>(
      isExpanded: true,
      value: app.language,
      underline: const SizedBox(),
      icon: const Icon(Icons.expand_more),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'so', child: Text('Soomaali')),
        DropdownMenuItem(
          value: 'ar',
          child: Text('\u0627\u0644\u0639\u0631\u0628\u064a\u0629'),
        ),
      ],
      onChanged: (v) {
        if (v != null) app.setSettings({'language': v});
      },
    );
  }
}

class AuthArtwork extends StatelessWidget {
  final IconData icon;
  final bool medicine;
  const AuthArtwork({super.key, required this.icon, this.medicine = false});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: motionDuration(context, 1000),
        curve: Curves.easeOutBack,
        builder: (_, value, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Transform.scale(scale: .92 + .08 * value, child: child),
        ),
        child: SizedBox(
          width: medicine ? 240 : 150,
          height: medicine ? 210 : 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: medicine ? 210 : 130,
                height: medicine ? 190 : 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFF5DAF6), Color(0xFFE3D5FF)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 20,
                child: Transform.rotate(
                  angle: -.5,
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF65AD64),
                    size: 66,
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 22,
                child: Transform.rotate(
                  angle: .5,
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF89C977),
                    size: 58,
                  ),
                ),
              ),
              Transform.rotate(
                angle: medicine ? -.15 : 0,
                child: Container(
                  width: medicine ? 114 : 92,
                  height: medicine ? 150 : 94,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD6B0FF),
                        Color(0xFF8C45E2),
                        Color(0xFF5925AB),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: .22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (medicine)
                        Container(
                          height: 20,
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      Icon(icon, size: medicine ? 62 : 54, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AccountWelcomeScreen extends StatelessWidget {
  const AccountWelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthFrame(
    back: false,
    children: [
      const AuthArtwork(icon: Icons.add_rounded, medicine: true),
      Consumer(
        builder: (context, ref, _) {
          final notice = ref.watch(appProvider).authNotice;
          return notice == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    tr(context, notice),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
        },
      ),
      const SizedBox(height: 20),
      const Text(
        'Daryeel',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          color: purple,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        tr(context, 'Your Personal Medicine Reminder'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, height: 1.4),
      ),
      const SizedBox(height: 30),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in [
            (Icons.notifications_none, 'Never miss a dose'),
            (Icons.calendar_month, 'Stay organized'),
            (Icons.favorite_border, 'Better health'),
          ])
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: lavender,
                    radius: 25,
                    child: Icon(item.$1, color: purple),
                  ),
                  const SizedBox(height: 10),
                  Text(tr(context, item.$2), textAlign: TextAlign.center),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 38),
      CareButton(
        onPressed: () => context.go('/auth?signup=true'),
        child: Text(tr(context, 'Create account')),
      ),
      const SizedBox(height: 14),
      OutlinedButton(
        onPressed: () => context.go('/auth'),
        child: Text(tr(context, 'Log In')),
      ),
      const GuestAccessButton(),
    ],
  );
}

class GuestAccessButton extends ConsumerWidget {
  final bool enabled;
  const GuestAccessButton({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      TextButton(
        onPressed: !enabled
            ? null
            : () async {
                final app = ref.read(appProvider);
                await app.continueAsGuest();
                if (!context.mounted) return;
                if (app.canAccessApp && app.error == null) {
                  context.go('/home');
                } else if (app.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, app.error!))),
                  );
                }
              },
        child: Text(tr(context, 'Continue as guest')),
      ),
      Text(
        tr(context, 'Saved on this device. Sign in for cloud backup.'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class AuthScreen extends ConsumerStatefulWidget {
  final bool recovery, signup, reset;
  const AuthScreen({
    super.key,
    this.recovery = false,
    this.signup = false,
    this.reset = false,
  });
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController(),
      name = TextEditingController();
  bool busy = false, hidePassword = true, hideConfirm = true, success = false;
  String? message;
  Future<void> google() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final launched = await ref
          .read(appProvider)
          .cloud!
          .auth
          .signInWithOAuth(OAuthProvider.google, redirectTo: authCallback);
      if (mounted) {
        setState(() {
          message = launched
              ? 'Complete sign in in your browser.'
              : 'Unable to connect. Please try again.';
          success = launched;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          message = 'Unable to connect. Please try again.';
          success = false;
        });
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() {
    for (final c in [email, password, confirm, name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !(form.currentState?.validate() ?? false)) return;
    final app = ref.read(appProvider);
    final cloud = app.cloud;
    if (cloud == null) return;
    app.authNotice = null;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      message = null;
      success = false;
    });
    try {
      if (widget.reset) {
        await cloud.auth.resetPasswordForEmail(
          email.text.trim(),
          redirectTo: authCallback,
        );
        message =
            'If this address has an account, a password reset link will arrive shortly.';
        success = true;
      } else if (widget.recovery) {
        if (!app.recoveringPassword || !app.signedIn) {
          throw const AuthException(
            'Recovery session required',
            code: 'otp_expired',
          );
        }
        await cloud.auth.updateUser(UserAttributes(password: password.text));
        if (!mounted) return;
        password.clear();
        confirm.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'Password updated.'))),
        );
        await app.finishRecovery();
        if (mounted) context.go('/home');
      } else {
        final result = widget.signup
            ? await cloud.auth.signUp(
                email: email.text.trim(),
                password: password.text,
                data: {'full_name': name.text.trim()},
                emailRedirectTo: authCallback,
              )
            : await cloud.auth.signInWithPassword(
                email: email.text.trim(),
                password: password.text,
              );
        if (!mounted) return;
        password.clear();
        confirm.clear();
        if (widget.signup && result.user?.identities?.isEmpty == true) {
          message =
              'An account may already exist. Try signing in or resetting your password.';
        } else if (result.session == null) {
          message = 'Check your email to confirm your account, then sign in.';
          success = true;
        } else {
          await app.settleAccount();
          if (mounted && app.canAccessApp) context.go('/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      message = e is AuthException
          ? authErrorMessage(e)
          : 'Unable to connect. Please try again.';
    }
    if (mounted) setState(() => busy = false);
  }

  Widget input(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool secret = false,
    bool confirmation = false,
    bool emailField = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(label),
      controller: controller,
      enabled: !busy,
      obscureText: secret && (confirmation ? hideConfirm : hidePassword),
      autocorrect: !secret && !emailField,
      enableSuggestions: !secret,
      keyboardType: emailField
          ? TextInputType.emailAddress
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      autofillHints: [
        emailField
            ? AutofillHints.email
            : secret
            ? (widget.signup || widget.recovery
                  ? AutofillHints.newPassword
                  : AutofillHints.password)
            : AutofillHints.name,
      ],
      decoration: InputDecoration(
        labelText: tr(context, label),
        prefixIcon: Icon(icon),
        suffixIcon: secret
            ? IconButton(
                tooltip: tr(
                  context,
                  (confirmation ? hideConfirm : hidePassword)
                      ? 'Show password'
                      : 'Hide password',
                ),
                onPressed: () => setState(() {
                  if (confirmation) {
                    hideConfirm = !hideConfirm;
                  } else {
                    hidePassword = !hidePassword;
                  }
                }),
                icon: Icon(
                  (confirmation ? hideConfirm : hidePassword)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
      validator: (v) {
        final value = v ?? '';
        if (value.trim().isEmpty) return tr(context, 'This field is required.');
        if (emailField &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
          return tr(context, 'Enter a valid email address.');
        }
        if (secret &&
            !confirmation &&
            (widget.signup || widget.recovery) &&
            value.length < 8) {
          return tr(context, 'Use at least 8 characters.');
        }
        if (confirmation && value != password.text) {
          return tr(context, 'Passwords do not match.');
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(appProvider).cloud != null;
    final authNotice = ref.watch(appProvider).authNotice;
    final title = widget.reset
        ? 'Forgot password?'
        : widget.recovery
        ? 'Choose a new password'
        : widget.signup
        ? 'Create account'
        : 'Log In';
    return AuthFrame(
      onBack: () async {
        if (busy) return;
        final router = GoRouter.of(context);
        if (widget.recovery) {
          final app = ref.read(appProvider);
          await app.run(() async {
            await app.cloud!.auth.signOut();
          });
          if (app.signedIn) return;
          router.go('/auth');
        } else {
          router.go('/welcome');
        }
      },
      children: [
        AuthArtwork(
          icon: widget.signup ? Icons.person_add_alt_1 : Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        Text(
          tr(context, title),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          tr(
            context,
            widget.signup
                ? 'Get started with Daryeel'
                : widget.reset || widget.recovery
                ? 'Secure access to your account'
                : 'Welcome back to Daryeel',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 30),
        if (authNotice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              tr(context, authNotice),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (!configured)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              tr(
                context,
                'Account service is not configured. Connect a Supabase project to enable sign in and password recovery.',
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        AutofillGroup(
          child: Form(
            key: form,
            child: Column(
              children: [
                if (widget.signup)
                  input('Full name', name, Icons.person_outline),
                if (!widget.recovery)
                  input('Email', email, Icons.mail_outline, emailField: true),
                if (!widget.reset)
                  input('Password', password, Icons.lock_outline, secret: true),
                if (widget.signup || widget.recovery)
                  input(
                    'Confirm password',
                    confirm,
                    Icons.lock_outline,
                    secret: true,
                    confirmation: true,
                  ),
              ],
            ),
          ),
        ),
        if (!widget.signup && !widget.reset && !widget.recovery)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: busy ? null : () => context.go('/auth?reset=true'),
              child: Text(tr(context, 'Forgot password?')),
            ),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                tr(context, message!),
                style: TextStyle(
                  color: success
                      ? const Color(0xFF19764F)
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        CareButton(
          onPressed: busy || !configured ? null : submit,
          child: busy
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  tr(
                    context,
                    widget.reset
                        ? 'Send reset link'
                        : widget.recovery
                        ? 'Save'
                        : widget.signup
                        ? 'Sign Up'
                        : 'Log In',
                  ),
                ),
        ),
        const SizedBox(height: 22),
        if (!widget.recovery) GuestAccessButton(enabled: !busy),
        if (const bool.fromEnvironment('GOOGLE_AUTH_ENABLED') &&
            !widget.recovery &&
            !widget.reset) ...[
          OutlinedButton.icon(
            onPressed: busy || !configured ? null : google,
            icon: const Icon(Icons.account_circle_outlined),
            label: Text(tr(context, 'Continue with Google')),
          ),
          const SizedBox(height: 16),
        ],
        if (!widget.recovery)
          TextButton(
            onPressed: busy
                ? null
                : () => context.go(
                    widget.signup || widget.reset
                        ? '/auth'
                        : '/auth?signup=true',
                  ),
            child: Text(
              tr(
                context,
                widget.signup
                    ? 'Already have an account? Log In'
                    : widget.reset
                    ? 'Log In'
                    : 'New to Daryeel? Create account',
              ),
            ),
          ),
      ],
    );
  }
}

String authErrorMessage(AuthException error) => switch (error.code) {
  'invalid_credentials' ||
  'user_not_found' => 'Check your email and password, then try again.',
  'email_not_confirmed' => 'Please confirm your email before signing in.',
  'user_already_exists' || 'email_exists' =>
    'An account may already exist. Try signing in or resetting your password.',
  'weak_password' =>
    'Use a stronger password that meets the server requirements.',
  'otp_expired' => 'This recovery link has expired. Request a new link.',
  'over_request_rate_limit' ||
  'over_email_send_rate_limit' => 'Please wait before trying again.',
  _ => 'Unable to connect. Please try again.',
};
