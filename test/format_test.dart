import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/utils/format.dart';

/// NumberFormat usa espaço não separável entre símbolo e valor.
String _normalize(String s) => s.replaceAll(' ', ' ');

void main() {
  group('formatCents', () {
    test('formata no padrão brasileiro', () {
      expect(_normalize(formatCents(123456)), r'R$ 1.234,56');
      expect(_normalize(formatCents(5)), r'R$ 0,05');
      expect(_normalize(formatCents(0)), r'R$ 0,00');
    });

    test('formatSignedCents indica o sinal', () {
      expect(_normalize(formatSignedCents(-1050)), r'- R$ 10,50');
      expect(_normalize(formatSignedCents(1050)), r'+ R$ 10,50');
    });
  });

  test('formatDate usa dd/MM/yyyy', () {
    expect(formatDate(DateTime(2026, 2, 1)), '01/02/2026');
  });

  group('parseCurrencyToCents', () {
    test('usa apenas os dígitos', () {
      expect(parseCurrencyToCents('1.234,56'), 123456);
      expect(parseCurrencyToCents(r'R$ 0,05'), 5);
      expect(parseCurrencyToCents(''), 0);
    });

    test('é o inverso de centsToInputText', () {
      for (final cents in [0, 1, 99, 100, 123456, 100000000]) {
        expect(parseCurrencyToCents(centsToInputText(cents)), cents);
      }
    });
  });

  group('CurrencyInputFormatter', () {
    const formatter = CurrencyInputFormatter();
    TextEditingValue type(String text) =>
        formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

    test('trata dígitos como centavos', () {
      expect(type('1').text, '0,01');
      expect(type('12345').text, '123,45');
      expect(type('123456789').text, '1.234.567,89');
    });

    test('remove zeros à esquerda e caracteres não numéricos', () {
      expect(type('0,012').text, '0,12');
      expect(type('abc').text, '');
    });
  });
}
