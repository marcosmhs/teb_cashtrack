import 'package:cloud_firestore/cloud_firestore.dart';

/// Lê datas gravadas como [Timestamp] (formato atual) ou como string ISO-8601
/// (formato legado). Retorna [fallback] (ou agora) quando o valor é inválido.
DateTime parseDate(Object? value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.now();
}

/// Lê valores monetários em centavos. Aceita o campo atual em centavos
/// ([centsKey]) ou o campo legado em reais como `double` ([legacyKey]).
int parseCents(Map<String, dynamic> map, String centsKey, String legacyKey) {
  final cents = map[centsKey];
  if (cents is num) return cents.round();
  final legacy = map[legacyKey];
  if (legacy is num) return (legacy * 100).round();
  return 0;
}

/// Retorna `null` para strings vazias, mantendo o valor nos demais casos.
String? nonEmptyString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}
