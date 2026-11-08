import 'local_controller.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:daryeel/main.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

void main() {
  testWidgets(
    'populated dashboard and medicine form remain usable at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late AppController app;
      await tester.runAsync(() async {
        if (Platform.environment['DARYEEL_CAPTURE'] == '1' &&
            Platform.isWindows) {
          debugDisableShadows = false;
          for (final family in ['Roboto', 'sans-serif', 'Ahem']) {
            final loader = FontLoader(family);
            for (final file in ['arial.ttf', 'arialbd.ttf']) {
              loader.addFont(
                Future.value(
                  ByteData.sublistView(
                    await File('C:/Windows/Fonts/$file').readAsBytes(),
                  ),
                ),
              );
            }
            await loader.load();
          }
          final icons = FontLoader('MaterialIcons');
          icons.addFont(
            Future.value(
              ByteData.sublistView(
                await File(
                  'C:/flutter/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                ).readAsBytes(),
              ),
            ),
          );
          await icons.load();
        }
        final db = await databaseFactoryMemory.openDatabase('preview');
        final repo = LocalRepository(db);
        await repo.saveSettings({'onboarded': true, 'name': 'Amina'});
        final now = DateTime.now();
        final names = [
          'Metformin',
          'Omega-3',
          'Iron',
          'Vitamin D3',
          'Magnesium',
        ];
        for (var i = 0; i < names.length; i++) {
          final minute = i < 3
              ? (7 + i) * 60
              : ((now.hour * 60 + now.minute + (i == 3 ? 10 : 60)) % 1440);
          final m = Medicine(
            id: 'preview-$i',
            name: names[i],
            dosage: i == 0 ? '500 mg' : '1 tablet',
            times: [minute],
            start: dayOnly(now),
          );
          await repo.put('guest', 'medicine', m.id, m.toJson());
          if (i < 3) {
            final d = generateDoses([m], now, now).first.change({
              'status': 'taken',
              'completedAt': now.toUtc().toIso8601String(),
            });
            await repo.put('guest', 'dose', d.id, d.toJson());
          }
        }
        app = LocalTestController(repo, ReminderService());
        await app.initialize();
      });
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: ProviderScope(
            overrides: [appProvider.overrideWith((ref) => app)],
            child: const DaryeelApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['DARYEEL_CAPTURE'] == '1') {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/dashboard-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        final router = GoRouter.of(tester.element(find.text('Amina')));
        final previews = {
          'schedule': '/schedule',
          'history': '/history',
          'profile': '/profile',
          'medicine': '/medicine/new',
          'reminder': '/alarm/${Uri.encodeComponent(app.today.last.id)}',
          'onboarding': '/onboarding',
        };
        for (final preview in previews.entries) {
          router.go(preview.value);
          await tester.pumpAndSettle();
          if (preview.key == 'onboarding') {
            await tester.runAsync(
              () => precacheImage(
                const ResizeImage(
                  AssetImage('assets/illustrations/care-today.png'),
                  width: 640,
                ),
                tester.element(find.byType(MaterialApp)),
              ),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull, reason: preview.key);
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'docs/${preview.key}-preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        router.go('/edit/preview-3');
        await tester.pumpAndSettle();
        for (var step = 0; step < 4; step++) {
          expect(tester.takeException(), isNull, reason: 'medicine step $step');
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'docs/medicine-step-${step + 1}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
          if (step < 3) {
            await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
            await tester.pumpAndSettle();
          }
        }
        router.go('/home');
        await tester.pumpAndSettle();
        debugDisableShadows = true;
      }
      await tester.tap(find.byTooltip('Add medicine'));
      await tester.pumpAndSettle();
      expect(find.text('Medicine name'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );
}
