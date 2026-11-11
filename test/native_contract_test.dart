import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/data/user_collections.dart';
import 'package:teb_cashtrack/models/account.dart';
import 'package:teb_cashtrack/models/notification_capture.dart';
import 'package:teb_cashtrack/models/transaction.dart';
import 'package:teb_cashtrack/services/notification_capture_service.dart';

/// Contrato entre o serviço nativo (Kotlin) e o app Flutter.
///
/// Os dois lados só se comunicam por textos: nome do canal e dos métodos,
/// coleções e campos do Firestore e status das capturas. Este teste lê o
/// código Kotlin e falha se algum desses textos divergir do lado Dart; sem ele,
/// renomear um campo de um lado só quebraria o lançamento automático em silêncio.
const _kotlinDir = 'android/app/src/main/kotlin/br/com/thatexoticbug/teb_cashtrack';

String _read(String path) => File(path).readAsStringSync();

final _processor = _read('$_kotlinDir/notifications/NotificationProcessor.kt');
final _mainActivity = _read('$_kotlinDir/MainActivity.kt');
final _settings = _read('$_kotlinDir/notifications/NotificationSettings.kt');
final _dartService = _read('lib/services/notification_capture_service.dart');
final _dartCapture = _read('lib/models/notification_capture.dart');

/// Todas as capturas do grupo 1 de [pattern] em [source]. Falha se não achar
/// nada: significa que o código mudou de forma e o teste precisa ser ajustado.
Set<String> _all(String source, String pattern, String what) {
  final values = {for (final m in RegExp(pattern).allMatches(source)) m.group(1)!};
  if (values.isEmpty) fail('Não encontrei $what; atualize o padrão em native_contract_test.dart.');
  return values;
}

String _one(String source, String pattern, String what) => _all(source, pattern, what).single;

/// Trecho de [source] entre `val name = hashMapOf<...>(` e o `)` que o fecha.
String _kotlinMap(String source, String name) {
  final match = RegExp('val $name = hashMapOf<[^>]*>\\(([\\s\\S]*?)\\n\\s*\\)').firstMatch(source);
  if (match == null) fail('Não encontrei o mapa "$name" no Kotlin.');
  return match.group(1)!;
}

Set<String> _keys(String kotlinMap) => _all(kotlinMap, r'"(\w+)" to ', 'as chaves do mapa');

void main() {
  group('canal MainActivity <-> NotificationCaptureService', () {
    test('mesmo nome de canal', () {
      expect(
        _one(_mainActivity, r'CHANNEL = "([^"]+)"', 'MainActivity.CHANNEL'),
        NotificationCaptureService.channelName,
      );
    });

    test('todo método chamado pelo Dart existe no Kotlin', () {
      final kotlin = _all(_mainActivity, r'"(\w+)" ->', 'os métodos do canal no Kotlin');
      final dart = _all(
        _dartService,
        r"invoke(?:Map)?Method(?:<[^>]*>)?\(\s*'(\w+)'",
        'as chamadas ao canal no Dart',
      );
      expect(kotlin, containsAll(dart));
    });

    test('getStatus devolve todas as chaves lidas pelo Dart', () {
      final kotlin = {
        ..._keys(_all(_settings, r'fun toMap\(\)[^(]*\(([\s\S]*?)\n\s*\)', 'toMap()').single),
        ..._all(_mainActivity, r'"(\w+)" to (?:has|is)\w+\(\)', 'as chaves extras de getStatus'),
      };
      final dart = _all(_dartService, r"map\['(\w+)'\]", 'as chaves lidas em fromMap');
      expect(kotlin, containsAll(dart));
    });

    test('saveSettings envia só chaves que o Kotlin lê', () {
      final kotlin = _all(_settings, r'map\["(\w+)"\]', 'as chaves lidas em update()');
      final call = _one(
        _dartService,
        r"invokeMethod\('saveSettings', \{([\s\S]*?)\}\)",
        'a chamada saveSettings',
      );
      expect(kotlin, containsAll(_all(call, r"'(\w+)':", 'as chaves de saveSettings')));
    });
  });

  group('Firestore: NotificationProcessor.kt <-> modelos Dart', () {
    test('coleções usadas pelo Kotlin existem no Dart', () {
      final kotlin = _all(_processor, r'collection\("(\w+)"\)', 'as coleções no Kotlin');
      expect({'users', ...UserCollections.all, UserCollections.notificationCaptures}, containsAll(kotlin));
    });

    test('lançamento gravado tem exatamente os campos de Transaction', () {
      final kotlin = _keys(_kotlinMap(_processor, 'transaction'));
      final dart = Transaction(
        id: 'x',
        date: DateTime(2026),
        accountId: 'a',
        amountCents: 1,
        type: TransactionType.debit,
      ).toMap().keys;
      expect(kotlin, unorderedEquals(dart));
    });

    test('tipo e origem do lançamento são valores conhecidos pelo Dart', () {
      final types = RegExp(r'if \(parsed\.isRefund\) "(\w+)" else "(\w+)"').firstMatch(_processor);
      if (types == null) fail('Não encontrei o tipo do lançamento no Kotlin.');
      expect(types.group(1), TransactionType.credit.storageKey);
      expect(types.group(2), TransactionType.debit.storageKey);
      expect(
        _one(_processor, r'"source" to "(\w+)"', 'a origem do lançamento'),
        Transaction.sourceNotification,
      );
    });

    test('captura gravada tem todos os campos lidos por NotificationCapture', () {
      final kotlin = {
        ..._keys(_kotlinMap(_processor, 'capture')),
        ..._all(_processor, r'capture\["(\w+)"\]', 'os campos extras da captura'),
      };
      final dart = _all(_dartCapture, r"map\['(\w+)'\]", 'os campos lidos em fromMap');
      expect(kotlin, containsAll(dart));
    });

    test('status gravados pelo Kotlin são os conhecidos pelo Dart', () {
      final kotlin = _all(_processor, r'saveCapture\("(\w+)"', 'os status no Kotlin');
      expect(kotlin, unorderedEquals(NotificationCapture.nativeStatuses));
      // Cada status (fora o de erro) tem um texto próprio na tela.
      final fallback = NotificationCapture.fromMap({'status': '?'}, 'x').statusLabel;
      for (final status in kotlin.difference({NotificationCapture.statusError})) {
        expect(
          NotificationCapture.fromMap({'status': status}, 'x').statusLabel,
          isNot(fallback),
          reason: 'status "$status" sem texto em NotificationCapture.statusLabel',
        );
      }
    });

    test('campos da conta lidos pelo Kotlin existem em Account', () {
      final kotlin = _all(_processor, r'get(?:String|Boolean)\("(\w+)"\)', 'os campos da conta');
      final dart = Account(
        id: 'x',
        name: 'Conta',
        type: AccountType.checking,
        initialBalanceCents: 0,
        active: true,
        createdAt: DateTime(2026),
      ).toMap().keys;
      expect(dart, containsAll(kotlin));
      expect(
        _one(_processor, r'getString\("type"\) == "(\w+)"', 'o tipo de cartão'),
        AccountType.creditCard.storageKey,
      );
    });
  });
}
