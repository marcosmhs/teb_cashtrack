import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/controllers/pluggy_controller.dart';
import 'package:teb_cashtrack/data/user_collections.dart';
import 'package:teb_cashtrack/models/account.dart';
import 'package:teb_cashtrack/models/import_settings.dart';
import 'package:teb_cashtrack/models/pluggy.dart';
import 'package:teb_cashtrack/models/transaction.dart';

void main() {
  group('ImportMode', () {
    test('sem configuração vale o modo notificações (comportamento anterior)', () {
      expect(ImportMode.parse(null), ImportMode.notifications);
      expect(ImportMode.parse('qualquer'), ImportMode.notifications);
    });

    test('lê os três modos', () {
      for (final mode in ImportMode.values) {
        expect(ImportMode.parse(mode.storageKey), mode);
      }
    });
  });

  group('PluggyAccount', () {
    test('cartão de crédito', () {
      final account = PluggyAccount.fromMap({
        'itemId': 'item',
        'name': 'Cartão',
        'marketingName': 'Cartão Platinum',
        'type': 'CREDIT',
        'number': '4821',
        'balanceCents': 152030,
        'cashtrackAccountId': 'cartao',
        'syncedThrough': Timestamp.fromDate(DateTime(2026, 11, 19)),
      }, 'p1');
      expect(account.isCreditCard, isTrue);
      expect(account.appType, AccountType.creditCard);
      expect(account.displayName, 'Cartão Platinum');
      expect(account.numberLabel, 'final 4821');
      expect(account.cashtrackAccountId, 'cartao');
      expect(account.syncedThrough, DateTime(2026, 11, 19));
    });

    test('conta bancária ainda não vinculada', () {
      final account = PluggyAccount.fromMap({'name': 'Conta', 'type': 'BANK'}, 'p2');
      expect(account.appType, AccountType.checking);
      expect(account.cashtrackAccountId, isNull);
      expect(account.syncedThrough, isNull);
    });
  });

  group('PluggyStatus.hasError', () {
    final ok = DateTime(2026, 11, 19, 7);
    final fail = DateTime(2026, 11, 19, 13);

    test('erro depois da última sincronização', () {
      expect(PluggyStatus(lastSyncAt: ok, lastError: 'x', lastErrorAt: fail).hasError, isTrue);
    });

    test('erro antigo, já resolvido por uma sincronização posterior', () {
      expect(PluggyStatus(lastSyncAt: fail, lastError: 'x', lastErrorAt: ok).hasError, isFalse);
    });
  });

  test('saldo inicial que iguala o saldo do app ao do banco', () {
    Transaction tx(String account, int cents, TransactionType type) => Transaction(
      id: '$account$cents',
      date: DateTime(2026, 11, 1),
      accountId: account,
      amountCents: cents,
      type: type,
    );
    final txs = [
      tx('conta', 650000, TransactionType.credit),
      tx('conta', 145000, TransactionType.debit),
      tx('outra', 999, TransactionType.debit),
    ];
    // Banco tem R$ 8.000,00; no app há +6.500 −1.450 = +5.050 → saldo inicial R$ 2.950,00.
    expect(PluggyController.initialBalanceToMatch(800000, 'conta', txs), 295000);
  });

  group('contrato com functions/src (TypeScript)', () {
    final sync = File('functions/src/sync.ts').readAsStringSync();
    final mapping = File('functions/src/mapping.ts').readAsStringSync();
    final index = File('functions/src/index.ts').readAsStringSync();

    test('coleções e documentos usados pelo servidor existem no app', () {
      final used = {for (final m in RegExp(r"collection\('(\w+)'\)").allMatches(sync)) m.group(1)!};
      expect({
        'users',
        ...UserCollections.all,
        UserCollections.pluggyAccounts,
        UserCollections.pluggyIgnored,
        UserCollections.settings,
      }, containsAll(used));
      expect(sync, contains("doc('${ImportSettings.docId}')"));
      expect(index, contains('settings/${PluggyStatus.docId}'));
    });

    test('modo e origem têm os mesmos valores', () {
      expect(sync, contains("MODE_PLUGGY = '${ImportMode.pluggy.storageKey}'"));
      expect(sync, contains(".get('${ImportSettings.modeField}')"));
      expect(mapping, contains("SOURCE_PLUGGY = '${Transaction.sourcePluggy}'"));
    });

    test('campos da conta do banco gravados pelo servidor e lidos pelo app', () {
      for (final field in ['itemId', 'name', 'marketingName', 'type', 'number', 'balanceCents']) {
        // Aceita `campo: valor` e a forma abreviada `campo,`.
        expect(
          RegExp('\\b$field[:,]').hasMatch(sync),
          isTrue,
          reason: 'campo "$field" não é gravado em sync.ts',
        );
      }
      expect(sync, contains("'${PluggyAccount.cashtrackAccountIdField}'"));
      expect(sync, contains("'${PluggyAccount.syncedThroughField}'"));
      expect(sync, contains('${PluggyAccount.syncedThroughField}: Timestamp'));
    });

    test('lançamento do banco tem os campos de Transaction', () {
      final dartFields = Transaction(
        id: 'x',
        date: DateTime(2026),
        accountId: 'a',
        amountCents: 1,
        type: TransactionType.debit,
      ).toMap().keys;
      for (final field in dartFields) {
        expect(
          mapping,
          contains('  $field:'),
          reason: 'campo "$field" não é gravado em mapping.ts',
        );
      }
    });

    test('estado da sincronização', () {
      for (final field in ['lastSyncAt', 'lastError', 'lastErrorAt']) {
        expect(index, contains('$field:'));
      }
      expect(sync, contains('imported:'));
    });
  });
}
