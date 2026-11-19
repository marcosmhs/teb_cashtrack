/**
 * Cloud Functions do CashTrack: integração com a Pluggy (Open Finance).
 *
 * As credenciais são do Meu Pluggy do dono do app, então a integração atende uma só
 * conta do CashTrack (PLUGGY_OWNER_UID). Configuração, uma vez (ver functions/README.md):
 *
 *   firebase functions:secrets:set PLUGGY_CLIENT_ID
 *   firebase functions:secrets:set PLUGGY_CLIENT_SECRET
 *   firebase functions:secrets:set PLUGGY_ITEM_IDS     (separados por vírgula)
 *   firebase functions:secrets:set PLUGGY_OWNER_UID    (uid do Firebase Auth)
 */
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { PluggyClient } from './pluggy';
import { syncUser, type SyncResult } from './sync';

initializeApp();

const clientId = defineSecret('PLUGGY_CLIENT_ID');
const clientSecret = defineSecret('PLUGGY_CLIENT_SECRET');
const itemIds = defineSecret('PLUGGY_ITEM_IDS');
const ownerUid = defineSecret('PLUGGY_OWNER_UID');

const options = {
  region: 'southamerica-east1',
  secrets: [clientId, clientSecret, itemIds, ownerUid],
  timeoutSeconds: 300,
  memory: '256MiB' as const,
};

async function runSync(trigger: 'schedule' | 'manual'): Promise<SyncResult> {
  const db = getFirestore();
  const uid = ownerUid.value().trim();
  const status = db.doc(`users/${uid}/settings/pluggy`);
  try {
    const result = await syncUser(
      db,
      new PluggyClient(clientId.value().trim(), clientSecret.value().trim()),
      uid,
      itemIds
        .value()
        .split(/[\s,;]+/)
        .filter(Boolean),
    );
    await status.set(
      { lastSyncAt: FieldValue.serverTimestamp(), trigger, ...result },
      { merge: true },
    );
    logger.info('Sincronização da Pluggy concluída', { trigger, ...result });
    return result;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error('Falha na sincronização da Pluggy', { trigger, message });
    await status.set(
      { lastError: message, lastErrorAt: FieldValue.serverTimestamp(), trigger },
      { merge: true },
    );
    throw error;
  }
}

/** Três vezes por dia: o Meu Pluggy atualiza os dados do banco uma vez por dia. */
export const pluggySyncScheduled = onSchedule(
  { ...options, schedule: '0 7,13,19 * * *', timeZone: 'America/Sao_Paulo' },
  async () => {
    await runSync('schedule');
  },
);

/** Botão "Sincronizar agora" do app. Só o dono das credenciais pode chamar. */
export const pluggySyncNow = onCall(options, async (request) => {
  if (!request.auth || request.auth.uid !== ownerUid.value().trim()) {
    throw new HttpsError(
      'permission-denied',
      'A integração com a Pluggy não está disponível para esta conta.',
    );
  }
  try {
    return await runSync('manual');
  } catch (error) {
    throw new HttpsError('internal', error instanceof Error ? error.message : String(error));
  }
});
