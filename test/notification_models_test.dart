import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/models/account.dart';
import 'package:teb_cashtrack/models/notification_capture.dart';
import 'package:teb_cashtrack/models/transaction.dart';

void main() {
  test('lançamento criado pelo serviço nativo é lido como automático', () {
    // Mesmo formato gravado por NotificationProcessor.kt.
    final tx = Transaction.fromMap({
      'date': Timestamp.fromDate(DateTime(2026, 10, 10, 12, 30)),
      'accountId': 'card',
      'amountCents': 4590,
      'details': 'Padaria Pao Quente',
      'tagId': null,
      'type': 'debit',
      'source': 'notification',
    }, 'notif_abc');
    expect(tx.isAutomatic, isTrue);
    expect(tx.signedCents, -4590);
    expect(tx.toMap()['source'], 'notification');
  });

  test('lançamento manual não tem origem', () {
    final tx = Transaction.fromMap({'amountCents': 100, 'type': 'debit'}, '1');
    expect(tx.isAutomatic, isFalse);
  });

  test('identificador de notificações da conta é persistido', () {
    final account = Account.fromMap({'name': 'Nubank', 'notificationMatch': ' 1234 '}, '1');
    expect(account.notificationMatch, '1234');
    expect(
      Account.fromMap({'name': 'Conta', 'notificationMatch': ''}, '2').notificationMatch,
      isNull,
    );
  });

  test('captura de notificação', () {
    final capture = NotificationCapture.fromMap({
      'package': 'com.samsung.android.spay',
      'title': 'Samsung Wallet',
      'text': 'R\$ 45,90 em PADARIA',
      'postedAt': Timestamp.fromDate(DateTime(2026, 10, 10)),
      'amountCents': 4590,
      'merchant': 'Padaria',
      'status': 'unmatched_account',
    }, 'c1');
    expect(capture.hasTransaction, isFalse);
    expect(capture.statusLabel, 'Conta não identificada');
    expect(NotificationCapture.fromMap({'status': 'created'}, 'c2').hasTransaction, isTrue);
  });
}
