import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_pix_section.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 1200,
            height: 1200,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('GiftsPixSection exibe textos principais e chave PIX', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      GiftsPixSection(onAddMessage: () {}),
    ));

    expect(find.text('Contribuição Afetiva Personalizada'), findsOneWidget);
    expect(find.text('Como funciona este carinho?'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
    expect(find.text('Enviar Recado com Presente'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('GiftsPixSection aciona callback de mensagem ao clicar no botão', (tester) async {
    bool messageClicked = false;

    await tester.pumpWidget(buildTestableWidget(
      GiftsPixSection(onAddMessage: () {
        messageClicked = true;
      }),
    ));

    await tester.tap(find.text('Enviar Recado com Presente'));
    expect(messageClicked, isTrue);
  });

  testWidgets('GiftsPixSection copia chave PIX ao clicar no botão de copiar', (tester) async {
    final List<MethodCall> log = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.pumpWidget(buildTestableWidget(
      GiftsPixSection(onAddMessage: () {}),
    ));

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();

    expect(log, isNotEmpty);
    expect(log.last.method, 'Clipboard.setData');
    expect(log.last.arguments, containsPair('text', 'amor@kleyoneliandra.com.br'));
  });
}
