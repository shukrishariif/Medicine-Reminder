import 'package:daryeel/core/brand_logo.dart';
import 'package:daryeel/core/premium.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('original logo fits narrow splash and respects reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StartupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(DaryeelLogo),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/daryeel-logo.png',
    );
    expect(image.fit, BoxFit.contain);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    expect(tester.takeException(), isNull);
  });
}
