import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_pix_section.dart';

void main() {
  testWidgets('PIX sem configuração fica oculto', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: GiftsPixSection())));
    expect(find.byIcon(Icons.content_copy), findsNothing);
    expect(find.text('ENVIAR RECADO COM PRESENTE'), findsNothing);
  });
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

  testWidgets('GiftsPixSection exibe textos principais e chave PIX',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      GiftsPixSection(
          pixKey: 'pix-teste@example.com',
          beneficiary: 'Beneficiário teste',
          onAddMessage: () {}),
    ));

    expect(find.text('CONTRIBUIÇÃO AFETIVA PERSONALIZADA'), findsOneWidget);
    expect(find.text('Como funciona este carinho?'), findsOneWidget);
    expect(find.text('01.'), findsOneWidget);
    expect(find.text('02.'), findsOneWidget);
    expect(find.text('03.'), findsOneWidget);
    expect(find.text('ENVIAR RECADO COM PRESENTE'), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
  });

  testWidgets('GiftsPixSection aciona callback de mensagem ao clicar no botão',
      (tester) async {
    bool messageClicked = false;

    await tester.pumpWidget(buildTestableWidget(
      GiftsPixSection(
          pixKey: 'pix-teste@example.com',
          beneficiary: 'Beneficiário teste',
          onAddMessage: () {
            messageClicked = true;
          }),
    ));

    await tester.tap(find.text('ENVIAR RECADO COM PRESENTE'));
    expect(messageClicked, isTrue);
  });

  testWidgets('GiftsPixSection copia chave PIX ao clicar no botão de copiar',
      (tester) async {
    final List<MethodCall> log = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.pumpWidget(buildTestableWidget(
      GiftsPixSection(
          pixKey: 'pix-teste@example.com',
          beneficiary: 'Beneficiário teste',
          onAddMessage: () {}),
    ));

    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pumpAndSettle();

    expect(log, isNotEmpty);
    expect(log.last.method, 'Clipboard.setData');
    expect(log.last.arguments, containsPair('text', 'pix-teste@example.com'));
  });
}
