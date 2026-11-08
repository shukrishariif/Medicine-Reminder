import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:daryeel/main.dart';
import 'package:daryeel/features/account_auth.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

// HTTP contract fixture only: never used by the application. Live Supabase,
// SMTP delivery, hashing, RLS and secure-device storage require staging tests.
class AuthContract {
  final requests = <http.Request>[];
  bool reject = false, confirmEmail = false, duplicate = false;
  String activeId = '11111111-1111-4111-8111-111111111111';
  late final client = SupabaseClient(
    'https://auth-contract.invalid',
    'test-public-key',
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path.endsWith('/sync_records')) return http.Response('[]', 200);
      if (path.endsWith('/logout') || path.endsWith('/recover')) {
        return http.Response('{}', 200);
      }
      if (reject) {
        return http.Response(
          jsonEncode({
            'error_code': 'invalid_credentials',
            'code': 'invalid_credentials',
            'msg': 'Invalid login credentials',
          }),
          400,
        );
      }
      final user = {
        'id': activeId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'person@example.com',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'app_metadata': {'provider': 'email'},
        'user_metadata': {
          'full_name': activeId.startsWith('1') ? 'User A' : 'User B',
        },
        'identities': duplicate
            ? []
            : [
                {
                  'id': activeId,
                  'user_id': activeId,
                  'identity_data': {'email': 'person@example.com'},
                  'provider': 'email',
                  'created_at': DateTime.now().toUtc().toIso8601String(),
                },
              ],
      };
      if (path.endsWith('/signup') && (confirmEmail || duplicate)) {
        return http.Response(jsonEncode(user), 200);
      }
      if (path.endsWith('/user')) return http.Response(jsonEncode(user), 200);
      String part(Object data) =>
          base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
      final token =
          '${part({'alg': 'HS256'})}.${part({'sub': activeId, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.signature';
      return http.Response(
        jsonEncode({
          'access_token': token,
          'token_type': 'bearer',
          'expires_in': 3600,
          'refresh_token': 'test-refresh-token',
          'user': user,
        }),
        200,
      );
    }),
  );
}

Future<AppController> makeController(
  String name, {
  SupabaseClient? cloud,
  bool onboarded = true,
}) async {
  final repository = LocalRepository(
    await databaseFactoryMemory.openDatabase(name),
  );
  await repository.saveSettings({'onboarded': onboarded});
  final app = AppController(repository, ReminderService(), cloud: cloud);
  await app.initialize();
  return app;
}

Future<void> mount(WidgetTester tester, AppController app) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appProvider.overrideWith((ref) => app)],
      child: const DaryeelApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String label, String value) async {
  final field = find.byKey(ValueKey(label));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> action(WidgetTester tester, String text) async {
  final button = find.widgetWithText(FilledButton, text);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(button);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

Future<void> close(
  WidgetTester tester,
  AppController app, [
  AuthContract? api,
]) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() async {
    await app.repository.db.close();
    await api?.client.dispose();
  });
}

void main() {
  testWidgets(
    'first-time onboarding ends at welcome; logged-out routes are protected',
    (tester) async {
      final app = await tester.runAsync(
        () => makeController('auth-routes', onboarded: false),
      );
      await mount(tester, app!);
      expect(find.byType(AccountWelcomeScreen), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('Skip'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect(find.byType(AccountWelcomeScreen), findsOneWidget);
      final router = GoRouter.of(
        tester.element(find.byType(AccountWelcomeScreen)),
      );
      for (final route in [
        '/home',
        '/medicine/new',
        '/history',
        '/alarm/private',
        '/auth?recovery=true',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          route.startsWith('/auth') ? '/auth' : '/welcome',
        );
      }
      expect(
        find.text(
          'Account service is not configured. Connect a Supabase project to enable sign in and password recovery.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Log In'))
            .onPressed,
        isNull,
      );
      await close(tester, app);
    },
  );
  testWidgets(
    'signup validates matching passwords and sends full name to real SDK',
    (tester) async {
      final api = AuthContract()..confirmEmail = true;
      final app = await tester.runAsync(
        () => makeController('auth-signup', cloud: api.client),
      );
      await mount(tester, app!);
      GoRouter.of(
        tester.element(find.byType(AccountWelcomeScreen)),
      ).go('/auth?signup=true');
      await tester.pumpAndSettle();
      await action(tester, 'Sign Up');
      expect(
        api.requests.where((r) => r.url.path.endsWith('/signup')),
        isEmpty,
      );
      await fill(tester, 'Full name', 'Amina Person');
      await fill(tester, 'Email', 'amina@example.com');
      await fill(tester, 'Password', 'entered-password');
      await fill(tester, 'Confirm password', 'different-password');
      await action(tester, 'Sign Up');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await fill(tester, 'Confirm password', 'entered-password');
      await action(tester, 'Sign Up');
      final request = api.requests.singleWhere(
        (r) => r.url.path.endsWith('/signup'),
      );
      expect(jsonDecode(request.body)['data']['full_name'], 'Amina Person');
      expect(app.canAccessApp, isFalse);
      expect(
        find.text('Check your email to confirm your account, then sign in.'),
        findsOneWidget,
      );
      expect(
        (await tester.runAsync(() => app.repository.settings())).toString(),
        isNot(contains('entered-password')),
      );
      await close(tester, app, api);
    },
  );
  testWidgets(
    'login rejects invalid credentials then opens the correct account',
    (tester) async {
      final api = AuthContract()..reject = true;
      final app = await tester.runAsync(
        () => makeController('auth-login', cloud: api.client),
      );
      await mount(tester, app!);
      GoRouter.of(
        tester.element(find.byType(AccountWelcomeScreen)),
      ).go('/auth');
      await tester.pumpAndSettle();
      await fill(tester, 'Email', 'person@example.com');
      await fill(tester, 'Password', 'wrong');
      await action(tester, 'Log In');
      expect(
        find.text('Check your email and password, then try again.'),
        findsOneWidget,
      );
      expect(app.canAccessApp, isFalse);
      api.reject = false;
      await fill(tester, 'Password', 'entered-password');
      await action(tester, 'Log In');
      expect(app.canAccessApp, isTrue);
      expect(find.text('User A'), findsOneWidget);
      await close(tester, app, api);
    },
  );
  test('account switches isolate data and restore owner records', () async {
    final api = AuthContract();
    final app = await makeController('auth-isolation', cloud: api.client);
    await api.client.auth.signInWithPassword(
      email: 'a@example.com',
      password: 'test-pass',
    );
    await Future<void>.delayed(Duration.zero);
    await app.settleAccount();
    final a = app.owner;
    await app.saveMedicine(
      Medicine(
        id: 'a-only',
        name: 'A medicine',
        dosage: 'Label dose',
        times: [480],
        start: DateTime.now(),
      ),
    );
    await api.client.auth.signOut();
    expect(app.canAccessApp, isFalse);
    await Future<void>.delayed(Duration.zero);
    await app.settleAccount();
    api.activeId = '22222222-2222-4222-8222-222222222222';
    await api.client.auth.signInWithPassword(
      email: 'b@example.com',
      password: 'test-pass',
    );
    await Future<void>.delayed(Duration.zero);
    await app.settleAccount();
    expect(app.owner, isNot(a));
    expect(app.medicines, isEmpty);
    expect(app.name, 'User B');
    await api.client.auth.signOut();
    await Future<void>.delayed(Duration.zero);
    await app.settleAccount();
    api.activeId = a;
    await api.client.auth.setSession('test-refresh-token');
    await Future<void>.delayed(Duration.zero);
    await app.settleAccount();
    expect(app.medicines.single.name, 'A medicine');
    expect(app.canAccessApp, isTrue);
    app.dispose();
    await app.repository.db.close();
    await api.client.dispose();
  });
  testWidgets('reset only reports accepted request after backend response', (
    tester,
  ) async {
    final api = AuthContract();
    final app = await tester.runAsync(
      () => makeController('auth-reset', cloud: api.client),
    );
    await mount(tester, app!);
    GoRouter.of(
      tester.element(find.byType(AccountWelcomeScreen)),
    ).go('/auth?reset=true');
    await tester.pumpAndSettle();
    await fill(tester, 'Email', 'person@example.com');
    await action(tester, 'Send reset link');
    expect(
      api.requests.where((r) => r.url.path.endsWith('/recover')).length,
      1,
    );
    expect(
      find.text(
        'If this address has an account, a password reset link will arrive shortly.',
      ),
      findsOneWidget,
    );
    expect(app.canAccessApp, isFalse);
    await close(tester, app, api);
  });
  testWidgets(
    'recovery event gates home and updates a matching password through SDK',
    (tester) async {
      final api = AuthContract();
      final app = await tester.runAsync(
        () => makeController('auth-recovery', cloud: api.client),
      );
      await mount(tester, app!);
      await tester.runAsync(() async {
        final session = (await api.client.auth.signInWithPassword(
          email: 'person@example.com',
          password: 'test-pass',
        )).session!;
        await api.client.auth.getSessionFromUrl(
          Uri.parse(
            'io.daryeel.app://login-callback/#access_token=${session.accessToken}&refresh_token=${session.refreshToken}&expires_in=3600&token_type=bearer&type=recovery',
          ),
        );
        await app.settleAccount();
      });
      await tester.pumpAndSettle();
      expect(app.recoveringPassword, isTrue);
      expect(find.text('Choose a new password'), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(AuthScreen)));
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await fill(tester, 'Password', 'new-entered-password');
      await fill(tester, 'Confirm password', 'new-entered-password');
      await action(tester, 'Save');
      expect(
        api.requests
            .where((r) => r.method == 'PUT' && r.url.path.endsWith('/user'))
            .length,
        1,
      );
      expect(app.recoveringPassword, isFalse);
      expect(find.text('User A'), findsOneWidget);
      await close(tester, app, api);
    },
  );

  testWidgets(
    'auth screens render and fit narrow large-text English Somali Arabic',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final api = AuthContract();
      final app = await tester.runAsync(
        () => makeController('auth-layouts', cloud: api.client),
      );
      final capture = GlobalKey();
      if (Platform.environment['DARYEEL_CAPTURE'] == '1') {
        if (Platform.isWindows) {
          await tester.runAsync(() async {
            for (final family in ['Roboto', 'sans-serif', 'Ahem']) {
              final font = FontLoader(family);
              for (final file in ['arial.ttf', 'arialbd.ttf']) {
                font.addFont(
                  Future.value(
                    ByteData.sublistView(
                      await File('C:/Windows/Fonts/$file').readAsBytes(),
                    ),
                  ),
                );
              }
              await font.load();
            }
          });
        }
        final loader = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await loader.load();
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: ProviderScope(
            overrides: [appProvider.overrideWith((ref) => app!)],
            child: const DaryeelApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(
        tester.element(find.byType(AccountWelcomeScreen)),
      );
      const routes = {
        'welcome': '/welcome',
        'signup': '/auth?signup=true',
        'login': '/auth',
        'reset': '/auth?reset=true',
      };
      for (final language in ['en', 'so', 'ar']) {
        await tester.runAsync(() => app!.setSettings({'language': language}));
        if (language != 'en') {
          tester.view.physicalSize = const Size(320, 780);
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        }
        for (final entry in routes.entries) {
          router.go(entry.value);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$language ${entry.key}',
          );
          if (language == 'en' &&
              Platform.environment['DARYEEL_CAPTURE'] == '1') {
            await tester.runAsync(() async {
              final image =
                  await (capture.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'docs/auth-${entry.key}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      }
      await close(tester, app!, api);
    },
  );
  testWidgets('duplicate signup response never grants a session', (
    tester,
  ) async {
    final api = AuthContract()..duplicate = true;
    final app = await tester.runAsync(
      () => makeController('auth-duplicate', cloud: api.client),
    );
    await mount(tester, app!);
    GoRouter.of(
      tester.element(find.byType(AccountWelcomeScreen)),
    ).go('/auth?signup=true');
    await tester.pumpAndSettle();
    await fill(tester, 'Full name', 'Person');
    await fill(tester, 'Email', 'person@example.com');
    await fill(tester, 'Password', 'entered-password');
    await fill(tester, 'Confirm password', 'entered-password');
    await action(tester, 'Sign Up');
    expect(app.canAccessApp, isFalse);
    expect(
      find.text(
        'An account may already exist. Try signing in or resetting your password.',
      ),
      findsOneWidget,
    );
    await close(tester, app, api);
  });
  test(
    'invalid recovery callbacks are handled without an unhandled stream error',
    () async {
      final api = AuthContract();
      final app = await makeController('auth-invalid-link', cloud: api.client);
      // Exercise the SDK error delivery used by its deep-link handler.
      // ignore: invalid_use_of_internal_member
      api.client.auth.notifyException(
        const AuthException('Expired link', code: 'otp_expired'),
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        app.authNotice,
        'Sign-in link could not be verified. Request a new link.',
      );
      expect(app.canAccessApp, isFalse);
      app.dispose();
      await app.repository.db.close();
      await api.client.dispose();
    },
  );
}
