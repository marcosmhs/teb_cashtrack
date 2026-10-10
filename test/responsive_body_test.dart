import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/widgets/common.dart';

void main() {
  testWidgets('na barra inferior, ocupa só a altura do conteúdo', (tester) async {
    // Regressão: o Align expandia até a altura total, a barra inferior cobria
    // a tela e o corpo ficava com altura zero (tela de lista de compras em branco).
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(key: Key('body')),
          bottomNavigationBar: ResponsiveBody(
            child: FilledButton(onPressed: () {}, child: const Text('Salvar')),
          ),
        ),
      ),
    );

    final screen = tester.getSize(find.byType(Scaffold)).height;
    final bar = tester.getSize(find.byType(ResponsiveBody)).height;
    expect(bar, lessThan(100));
    expect(tester.getSize(find.byKey(const Key('body'))).height, greaterThan(screen - 100));
  });

  testWidgets('no corpo, mantém altura limitada para listas roláveis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveBody(
            child: ListView(children: [for (var i = 0; i < 50; i++) Text('Item $i')]),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Item 0'), findsOneWidget);
  });
}
