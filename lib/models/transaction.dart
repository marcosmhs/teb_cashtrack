import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../utils/firestore_parse.dart';

enum TransactionType {
  debit('debit', 'Débito'),
  credit('credit', 'Crédito');

  const TransactionType(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static TransactionType parse(Object? value) {
    final key = (value as String?)?.toLowerCase();
    return TransactionType.values.firstWhere(
      (t) => t.storageKey == key,
      orElse: () => TransactionType.debit,
    );
  }
}

class Transaction {
  final String id;
  final DateTime date;
  final String accountId;

  /// Valor sempre positivo, em centavos. O sinal é dado por [type].
  final int amountCents;
  final String? details;
  final String? tagId;
  final TransactionType type;

  /// Origem do lançamento: `null` = manual; `notification` = criado a partir de
  /// uma notificação de pagamento (Android).
  final String? source;

  const Transaction({
    required this.id,
    required this.date,
    required this.accountId,
    required this.amountCents,
    this.details,
    this.tagId,
    required this.type,
    this.source,
  });

  static const sourceNotification = 'notification';

  bool get isAutomatic => source == sourceNotification;

  bool get isDebit => type == TransactionType.debit;

  /// Créditos aumentam o saldo, débitos reduzem.
  int get signedCents => isDebit ? -amountCents : amountCents;

  /// Texto principal exibido em listas.
  String get title => details ?? type.label;

  Transaction copyWith({String? tagId, bool clearTag = false}) {
    return Transaction(
      id: id,
      date: date,
      accountId: accountId,
      amountCents: amountCents,
      details: details,
      tagId: clearTag ? null : (tagId ?? this.tagId),
      type: type,
      source: source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'accountId': accountId,
      'amountCents': amountCents,
      'details': details,
      'tagId': tagId,
      'type': type.storageKey,
      'source': source,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      date: parseDate(map['date']),
      accountId: map['accountId'] as String? ?? '',
      amountCents: parseCents(map, 'amountCents', 'amount').abs(),
      details: nonEmptyString(map['details']),
      tagId: nonEmptyString(map['tagId']),
      type: TransactionType.parse(map['type']),
      source: nonEmptyString(map['source']),
    );
  }
}
