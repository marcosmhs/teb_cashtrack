import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/services/tag_stats.dart';
import 'package:teb_cashtrack/theme.dart';
import 'package:teb_cashtrack/views/tag_spending_view.dart';

void main() {
  Future<void> pumpRow(WidgetTester tester, {required double fraction, String label = 'Mercado'}) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TagBarRow(
            label: label,
            total: const TagTotal(tagId: 'm', cents: 123456789, count: 12),
            fraction: fraction,
            share: 0.425,
            muted: false,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('cabe em tela estreita com nome longo e valor alto', (tester) async {
    await pumpRow(
      tester,
      fraction: 1,
      label: 'Supermercado e padaria do bairro com nome bem comprido',
    );
    expect(tester.takeException(), isNull);
    expect(find.text('43% · 12 lançamentos'), findsOneWidget);
  });

  testWidgets('barra mantém largura mínima para valores pequenos', (tester) async {
    await pumpRow(tester, fraction: 0.0001);
    expect(tester.takeException(), isNull);
    final bar = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) => c.constraints?.maxHeight == 8);
    expect(bar.constraints!.maxWidth, greaterThanOrEqualTo(4));
  });
}
