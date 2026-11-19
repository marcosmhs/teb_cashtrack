import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, FieldValue, SetOptions;
import 'package:flutter/foundation.dart';

import '../data/local_first.dart';
import '../data/user_collections.dart';
import '../models/import_settings.dart';
import '../services/notification_capture_service.dart';

class ImportSettingsController {
  DocumentReference<Map<String, dynamic>> get _doc =>
      UserCollections.of(UserCollections.settings).doc(ImportSettings.docId);

  Stream<ImportMode> watchMode() =>
      _doc.snapshots().map((s) => ImportMode.parse(s.data()?[ImportSettings.modeField]));

  /// Salva a escolha. No Android também liga ou desliga a captura de notificações
  /// neste aparelho, para o serviço nem chegar a processar quando não for usado.
  Future<void> setMode(ImportMode mode) async {
    await writeLocal(
      _doc.set({
        ImportSettings.modeField: mode.storageKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      'a forma de lançamento automático',
    );
    if (!NotificationCaptureService.isSupported) return;
    try {
      await NotificationCaptureService().saveSettings(enabled: mode == ImportMode.notifications);
    } catch (e) {
      debugPrint('Erro ao atualizar a captura de notificações: $e');
    }
  }
}
