import 'package:daryeel/core/auth_strings.dart';
import 'local_controller.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:daryeel/core/strings.dart';
import 'package:daryeel/core/translations_extra.dart';
import 'package:daryeel/core/somali_material.dart';
import 'package:daryeel/core/motion.dart';
import 'package:daryeel/core/medicine_strings.dart';
import 'package:daryeel/main.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

void main() {
  test(
    'all application catalog entries have Somali and Arabic translations',
    () {
      for (final entry in {
        ...AppStrings.translations,
        ...extraTranslations,
        ...medicineTranslations,
        ...authTranslations,
      }.entries) {
        for (final locale in ['so', 'ar']) {
          expect(
            entry.value[locale],
            isNotNull,
            reason: '${entry.key}: $locale',
          );
          expect(entry.value[locale]!.trim(), isNotEmpty, reason: entry.key);
          expect(
            AppStrings(locale)(entry.key),
            isNot(entry.key),
            reason: entry.key,
          );
        }
      }
    },
  );
  test(
    'literal localized widgets and domain validation messages cannot silently fall back',
    () {
      final files = [
        ...Directory(
          'lib/features',
        ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart')),
        File('lib/data/models.dart'),
      ];
      final literal = RegExp(
        r"(?:LocalizedText\(|tr\(context,|tr\(ctx,|FormatException\()\s*'((?:\\.|[^'\\])*)'",
      );
      for (final file in files) {
        for (final match in literal.allMatches(file.readAsStringSync())) {
          final key = match[1]!.replaceAll(r'\n', '\n');
          if (key.contains(r'$') ||
              ['Daryeel', 'English', 'Soomaali', 'العربية'].contains(key)) {
            continue;
          }
          expect(
            AppStrings('so')(key),
            isNot(key),
            reason: '${file.path}: $key',
          );
          expect(
            AppStrings('ar')(key),
            isNot(key),
            reason: '${file.path}: $key',
          );
        }
      }
    },
  );
  test('Somali dates and Material picker controls are localized', () {
    const localizations = SomaliMaterialLocalizations();
    expect(
      localizations.formatFullDate(DateTime(2026, 10, 27)),
      'Talaado, 27 Oktoobar 2026',
    );
    expect(localizations.formatMonthYear(DateTime(2026, 2)), 'Febraayo 2026');
    expect(localizations.cancelButtonLabel, 'Jooji');
    expect(localizations.timePickerDialHelpText, 'Dooro waqti');
    expect(
      localizations.parseCompactDate(
        localizations.formatCompactDate(DateTime(2026, 10, 27)),
      ),
      DateTime(2026, 10, 27),
    );
  });
  testWidgets(
    'reduced motion shows content immediately without entrance effects',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SoftEntrance(child: Text('Visible')),
          ),
        ),
      );
      expect(find.text('Visible'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SoftEntrance),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SoftEntrance),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
    },
  );
  for (final language in ['so', 'ar']) {
    testWidgets(
      '$language translates onboarding, settings, form validation and calendar',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late AppController app;
        await tester.runAsync(() async {
          final db = await databaseFactoryMemory.openDatabase(
            'locale-$language',
          );
          final repo = LocalRepository(db);
          await repo.saveSettings({'language': language});
          app = LocalTestController(repo, ReminderService());
          await app.initialize();
        });
        final t = AppStrings(language);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appProvider.overrideWith((ref) => app)],
            child: const DaryeelApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(t('Daryeel helps you remember your medicines easily.')),
          findsOneWidget,
        );
        final router = GoRouter.of(tester.element(find.text('Daryeel')));
        await tester.runAsync(() => app.setSettings({'onboarded': true}));
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(
          find.text(t('Hide medicine details on lock screen')),
          findsOneWidget,
        );
        expect(find.text('Full-screen reminders'), findsNothing);
        router.go('/medicine/new');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, t('Continue')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, t('Continue')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(t('Enter a medicine name')),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text(t('Enter a medicine name')), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'My prescribed medicine',
        );

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, t('Continue')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, t('Continue')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('Dosage')),
          '1 capsule',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, t('Continue')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(t('Start date')),
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(t('Start date')));
        await tester.pumpAndSettle();
        final picker = tester.element(find.byType(DatePickerDialog));
        final pickerTitle = MaterialLocalizations.of(picker).datePickerHelpText;
        expect(pickerTitle, isNot('Select date'));
        expect(find.text(pickerTitle), findsOneWidget);
        expect(find.text('Select date'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => app.repository.db.close());
      },
    );
  }
}
