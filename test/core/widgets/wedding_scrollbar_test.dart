import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/app.dart';

void main() {
  testWidgets('barra lateral única permite arrastar no desktop',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.linux),
      scrollBehavior: WeddingScrollBehavior(),
      home: Scaffold(
          body: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: controller,
          physics: const ClampingScrollPhysics(),
          child: const SizedBox(width: double.infinity, height: 3000),
        ),
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), findsOneWidget);
    final bounds = tester.getRect(find.byType(Scrollbar));
    final gesture = await tester.startGesture(
      Offset(bounds.right - 5, bounds.top + 30),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 160));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
  });
}
