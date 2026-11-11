import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/data/local_first.dart';
import 'package:teb_cashtrack/services/sync_status.dart';

void main() {
  // writeLocal avisa falhas pelo ScaffoldMessenger, que depende do binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('writeLocal', () {
    test('não espera a confirmação da nuvem (sem conexão ela nunca chega)', () async {
      final neverConfirmed = Completer<void>().future;
      await writeLocal(neverConfirmed, 'o lançamento').timeout(const Duration(seconds: 1));
    });

    test('falha da sincronização não derruba quem gravou', () async {
      final failed = Future<void>.error(StateError('permission-denied'));
      await writeLocal(failed, 'o lançamento');
      // Deixa o erro ser tratado; se escapasse, o teste falharia como erro não tratado.
      await pumpEventQueue();
    });
  });

  group('SyncState.resolve', () {
    test('sincronizado', () {
      expect(SyncState.resolve(hasPendingWrites: false, isFromCache: false), SyncState.synced);
    });

    test('enviando alterações', () {
      expect(SyncState.resolve(hasPendingWrites: true, isFromCache: false), SyncState.syncing);
    });

    test('sem conexão', () {
      expect(SyncState.resolve(hasPendingWrites: false, isFromCache: true), SyncState.offline);
    });

    test('sem conexão com alterações guardadas no aparelho', () {
      expect(
        SyncState.resolve(hasPendingWrites: true, isFromCache: true),
        SyncState.offlinePending,
      );
    });
  });
}
