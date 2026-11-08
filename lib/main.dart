import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'core/motion.dart';
import 'core/premium.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'services/app_controller.dart';
import 'services/reminders.dart';
import 'services/secure_session.dart';
import 'features/auth.dart';
import 'features/dashboard.dart';
import 'features/medicine.dart';
import 'features/profile.dart';
import 'features/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      home: const StartupScreen(),
    ),
  );
  try {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
    SupabaseClient? cloud;
    var recoveryPending = false;
    var recoveryFailed = false;
    StreamSubscription<AuthState>? startupAuth;
    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: const FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(),
        ),
      );
      cloud = Supabase.instance.client;
      startupAuth = cloud.auth.onAuthStateChange.listen(
        (event) {
          if (event.event == AuthChangeEvent.passwordRecovery) {
            recoveryPending = true;
          }
        },
        onError: (Object error, StackTrace stack) {
          recoveryFailed = true;
        },
      );
    }
    final reminders = ReminderService();
    String? warning;
    try {
      await reminders.initialize();
    } catch (_) {
      warning =
          'Reminders are unavailable. Open Alarm settings to check permissions.';
    }
    final controller = AppController(
      LocalRepository(await openLocalDatabase()),
      reminders,
      cloud: cloud,
    );
    await controller.initialize();
    controller.recoveringPassword =
        controller.recoveringPassword || recoveryPending;
    if (recoveryFailed) {
      controller.recoveringPassword = false;
      controller.authNotice =
          'Sign-in link could not be verified. Request a new link.';
    }
    await startupAuth?.cancel();
    controller.error ??= warning;
    runApp(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => controller)],
        child: const DaryeelApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    size: 64,
                    color: purple,
                  ),
                  const SizedBox(height: 20),
                  const LocalizedText(
                    'Daryeel could not open your local storage. Please restart the app. Your existing data has not been removed.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: main,
                    child: const LocalizedText('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DaryeelApp extends ConsumerStatefulWidget {
  const DaryeelApp({super.key});
  @override
  ConsumerState<DaryeelApp> createState() => _DaryeelAppState();
}

class _DaryeelAppState extends ConsumerState<DaryeelApp>
    with WidgetsBindingObserver {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final app = ref.read(appProvider);
    router = GoRouter(
      initialLocation: app.canAccessApp
          ? '/home'
          : app.onboarded
          ? '/welcome'
          : '/onboarding',
      refreshListenable: app,
      redirect: (_, state) {
        final path = state.uri.path;
        if (app.recoveringPassword) {
          return path == '/auth' &&
                  state.uri.queryParameters['recovery'] == 'true'
              ? null
              : '/auth?recovery=true';
        }
        if (app.canAccessApp) {
          if (app.guestMode) return null;
          return ['/welcome', '/auth'].contains(path) ? '/home' : null;
        }
        if (!app.onboarded) return path == '/onboarding' ? null : '/onboarding';
        if (path == '/onboarding') return '/welcome';
        if (path == '/auth' &&
            state.uri.queryParameters['recovery'] == 'true') {
          return '/auth';
        }
        return ['/welcome', '/auth'].contains(path) ? null : '/welcome';
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (_, _) => const AccountWelcomeScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, state) => AuthScreen(
            key: ValueKey(state.uri.toString()),
            recovery: state.uri.queryParameters['recovery'] == 'true',
            signup: state.uri.queryParameters['signup'] == 'true',
            reset: state.uri.queryParameters['reset'] == 'true',
          ),
        ),
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(path: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            GoRoute(
              path: '/schedule',
              builder: (_, _) => const ScheduleScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (_, _) => const ScheduleScreen(history: true),
            ),
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        ),
        GoRoute(
          path: '/medicines',
          builder: (_, _) => const MedicineListScreen(),
        ),
        GoRoute(
          path: '/medicine/new',
          builder: (_, _) => const MedicineEditor(),
        ),
        GoRoute(
          path: '/medicine/:id',
          builder: (_, state) =>
              MedicineDetails(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/edit/:id',
          builder: (_, state) =>
              MedicineEditor(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/alarm/:id',
          builder: (_, state) => AlarmScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const AlarmSettingsScreen(),
        ),
      ],
    );
    void openReminder(String id) {
      router.push(
        id.startsWith('refill:')
            ? '/medicine/${Uri.encodeComponent(id.substring(7))}'
            : '/alarm/${Uri.encodeComponent(id)}',
      );
    }

    app.reminders.onOpen = openReminder;
    final launch = app.reminders.launchDose;
    if (launch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openReminder(launch));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appProvider).resume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    return MaterialApp.router(
      title: 'Daryeel',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: app.settings['dark'] == true
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: Locale(app.language),
      supportedLocales: AppStrings.supported,
      localizationsDelegates: AppStrings.delegates,
      localeResolutionCallback: (locale, supported) => Locale(app.language),
    );
  }
}

class AppShell extends ConsumerWidget {
  final String path;
  final Widget child;
  const AppShell({super.key, required this.path, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final index = ['/home', '/schedule', '/history', '/profile'].indexOf(path);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (app.error != null)
              MaterialBanner(
                content: LocalizedText(app.error!),
                actions: [
                  TextButton(
                    onPressed: () {
                      app.error = null;
                      app.setSettings({});
                    },
                    child: const LocalizedText('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: SoftEntrance(key: ValueKey(path), child: child),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const AddMedicineButton(),
      bottomNavigationBar: DaryeelNavigation(index: index < 0 ? 0 : index),
    );
  }
}
