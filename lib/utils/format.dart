import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final NumberFormat _decimal = NumberFormat.currency(locale: 'pt_BR', symbol: '');
final DateFormat _date = DateFormat('dd/MM/yyyy');

/// `123456` → `R$ 1.234,56`
String formatCents(int cents) => _currency.format(cents / 100);

/// `-123456` → `- R$ 1.234,56`; `123456` → `+ R$ 1.234,56`
String formatSignedCents(int cents) => '${cents < 0 ? '-' : '+'} ${formatCents(cents.abs())}';

/// `123456` → `1.234,56` (sem símbolo, para campos de entrada).
String centsToInputText(int cents) => _decimal.format(cents / 100).trim();

/// `01/02/2026`
String formatDate(DateTime date) => _date.format(date);

/// Converte o texto digitado (qualquer formato) em centavos, usando apenas os dígitos.
int parseCurrencyToCents(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits);
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Formata a entrada como moeda brasileira enquanto o usuário digita,
/// tratando os dígitos como centavos: `1` → `0,01`, `12345` → `123,45`.
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter({this.maxDigits = 13});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final text = centsToInputText(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
