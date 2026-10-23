import '../data/user_collections.dart';
import '../models/notification_capture.dart';

class NotificationCaptureController {
  JsonCollection get _collection => UserCollections.of(UserCollections.notificationCaptures);

  /// Capturas mais recentes primeiro.
  Stream<List<NotificationCapture>> getCaptures({int limit = 50}) {
    return _collection
        .orderBy('postedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => NotificationCapture.fromMap(d.data(), d.id)).toList());
  }

  Future<void> markCreatedManually(String captureId, String transactionId) async {
    await _collection.doc(captureId).update({
      'status': NotificationCapture.statusCreatedManually,
      'transactionId': transactionId,
    });
  }

  Future<void> delete(String captureId) async {
    await _collection.doc(captureId).delete();
  }
}
