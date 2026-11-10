import 'package:cloud_firestore/cloud_firestore.dart' show SnapshotMetadata;
import 'package:rxdart/rxdart.dart';

import '../data/user_collections.dart';

/// Estado da sincronização entre o banco do aparelho e a nuvem.
enum SyncState {
  synced('Tudo sincronizado com a nuvem.'),
  syncing('Enviando alterações para a nuvem…'),
  offline('Sem conexão. Mostrando os dados salvos no aparelho.'),
  offlinePending(
    'Sem conexão. As alterações ficam salvas no aparelho e serão enviadas '
    'quando a conexão voltar.',
  );

  const SyncState(this.description);

  final String description;

  /// [hasPendingWrites]: há gravações locais que o servidor ainda não confirmou.
  /// [isFromCache]: os dados vieram só do aparelho (sem contato com o servidor).
  static SyncState resolve({required bool hasPendingWrites, required bool isFromCache}) {
    if (isFromCache) return hasPendingWrites ? offlinePending : offline;
    return hasPendingWrites ? syncing : synced;
  }
}

/// Acompanha o estado de sincronização pelas coleções do usuário.
class SyncStatusService {
  Stream<SyncState> watch() {
    final metadata = [
      for (final name in UserCollections.all)
        UserCollections.of(name).snapshots(includeMetadataChanges: true).map((s) => s.metadata),
    ];
    return Rx.combineLatestList<SnapshotMetadata>(metadata)
        .map(
          (all) => SyncState.resolve(
            hasPendingWrites: all.any((m) => m.hasPendingWrites),
            isFromCache: all.any((m) => m.isFromCache),
          ),
        )
        .distinct();
  }
}
