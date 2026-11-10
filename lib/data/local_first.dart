import 'dart:async';

import 'package:flutter/material.dart';

/// Chave do [ScaffoldMessenger] do app, para avisar falhas de sincronização
/// que acontecem depois que a tela que fez a gravação já foi fechada.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Grava no banco local sem esperar a nuvem.
///
/// O Firestore aplica a gravação no banco do aparelho na hora (as telas já
/// mostram a mudança) e a envia ao servidor quando houver conexão, mas o
/// `Future` de `set`/`update`/`delete`/`commit` só termina quando o servidor
/// confirma. Esperar por ele deixaria o app travado sem internet. Falhas da
/// sincronização (ex.: regras do Firestore) são avisadas em [appMessengerKey].
Future<void> writeLocal(Future<void> write, String what) {
  unawaited(
    write.catchError((Object error) {
      debugPrint('Falha ao sincronizar $what: $error');
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Não foi possível sincronizar $what com a nuvem.')),
      );
    }),
  );
  return Future.value();
}
