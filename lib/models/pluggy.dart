import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../utils/firestore_parse.dart';
import 'account.dart';

/// Conta encontrada na Pluggy, em `users/{uid}/pluggy_accounts/{id}`.
///
/// Os dados do banco são gravados pela sincronização (functions/src/sync.ts);
/// o app só grava [cashtrackAccountId], a conta do app que recebe os lançamentos.
class PluggyAccount {
  final String id;
  final String itemId;
  final String name;
  final String? marketingName;

  /// `BANK` ou `CREDIT`, como na API da Pluggy.
  final String type;

  /// Conta bancária: número da conta. Cartão: os 4 últimos dígitos.
  final String? number;

  /// Conta bancária: saldo disponível. Cartão: fatura em aberto.
  final int balanceCents;

  /// `null` = não importar os lançamentos desta conta.
  final String? cashtrackAccountId;

  /// Até quando os lançamentos já foram importados (`null` = nunca).
  final DateTime? syncedThrough;

  const PluggyAccount({
    required this.id,
    required this.itemId,
    required this.name,
    this.marketingName,
    required this.type,
    this.number,
    required this.balanceCents,
    this.cashtrackAccountId,
    this.syncedThrough,
  });

  static const cashtrackAccountIdField = 'cashtrackAccountId';
  static const syncedThroughField = 'syncedThrough';

  bool get isCreditCard => type == 'CREDIT';

  AccountType get appType => isCreditCard ? AccountType.creditCard : AccountType.checking;

  String get displayName => marketingName ?? name;

  /// Ex.: "final 4821" para cartões.
  String? get numberLabel {
    if (number == null) return null;
    return isCreditCard ? 'final $number' : 'conta $number';
  }

  factory PluggyAccount.fromMap(Map<String, dynamic> map, String id) {
    final synced = map[syncedThroughField];
    return PluggyAccount(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      name: map['name'] as String? ?? 'Conta',
      marketingName: nonEmptyString(map['marketingName']),
      type: map['type'] as String? ?? 'BANK',
      number: nonEmptyString(map['number']),
      balanceCents: (map['balanceCents'] as num?)?.round() ?? 0,
      cashtrackAccountId: nonEmptyString(map[cashtrackAccountIdField]),
      syncedThrough: synced is Timestamp ? synced.toDate() : null,
    );
  }
}

/// Estado da sincronização, em `users/{uid}/settings/pluggy`. O documento só existe
/// para o dono das credenciais da Pluggy configuradas no servidor (ver functions/).
class PluggyStatus {
  final DateTime? lastSyncAt;
  final String? lastError;
  final DateTime? lastErrorAt;

  /// Lançamentos novos na última sincronização.
  final int imported;

  const PluggyStatus({this.lastSyncAt, this.lastError, this.lastErrorAt, this.imported = 0});

  static const docId = 'pluggy';

  factory PluggyStatus.fromMap(Map<String, dynamic> map) {
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;
    return PluggyStatus(
      lastSyncAt: date(map['lastSyncAt']),
      lastError: nonEmptyString(map['lastError']),
      lastErrorAt: date(map['lastErrorAt']),
      imported: (map['imported'] as num?)?.toInt() ?? 0,
    );
  }

  /// O último erro aconteceu depois da última sincronização bem-sucedida.
  bool get hasError {
    if (lastError == null) return false;
    if (lastSyncAt == null || lastErrorAt == null) return true;
    return lastErrorAt!.isAfter(lastSyncAt!);
  }
}
