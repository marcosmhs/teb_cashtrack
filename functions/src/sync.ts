/**
 * Sincroniza as contas e transações da Pluggy de um usuário com o Firestore:
 *
 * - `users/{uid}/pluggy_accounts/{id}`: contas do banco, sempre atualizadas. O app grava
 *   `cashtrackAccountId` para dizer em qual conta do app os lançamentos devem entrar.
 * - `users/{uid}/transactions/pluggy_{id}`: lançamentos, só das contas vinculadas e só
 *   quando o usuário escolheu o modo Pluggy (`settings/import`, campo `mode`).
 * - `users/{uid}/pluggy_ignored/{docId}`: lançamentos que o usuário excluiu; não voltam.
 */
import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';

import {
  bankFields,
  creationFields,
  shouldImport,
  SOURCE_PLUGGY,
  syncDateFrom,
  tagHistory,
  transactionDocId,
} from './mapping';
import type { PluggyClient } from './pluggy';

/** Igual a `ImportMode.pluggy.storageKey` no app. */
export const MODE_PLUGGY = 'pluggy';

export interface SyncResult {
  accounts: number;
  imported: number;
  updated: number;
}

interface ImportContext {
  existing: Set<string>;
  ignored: Set<string>;
  tags: Map<string, string>;
}

async function loadContext(user: DocumentReference): Promise<ImportContext> {
  const [pluggy, ignored, tagged] = await Promise.all([
    user.collection('transactions').where('source', '==', SOURCE_PLUGGY).select().get(),
    user.collection('pluggy_ignored').select().get(),
    user.collection('transactions').select('details', 'tagId', 'date').get(),
  ]);
  return {
    existing: new Set(pluggy.docs.map((d) => d.id)),
    ignored: new Set(ignored.docs.map((d) => d.id)),
    tags: tagHistory(
      tagged.docs.map((d) => ({
        details: d.get('details'),
        tagId: d.get('tagId'),
        date: (d.get('date') as Timestamp | undefined)?.toDate() ?? new Date(0),
      })),
    ),
  };
}

export async function syncUser(
  db: Firestore,
  client: PluggyClient,
  uid: string,
  itemIds: string[],
  now = new Date(),
): Promise<SyncResult> {
  const user = db.collection('users').doc(uid);
  const mode = (await user.collection('settings').doc('import').get()).get('mode');
  const importing = mode === MODE_PLUGGY;

  const links = new Map(
    (await user.collection('pluggy_accounts').get()).docs.map((d) => [
      d.id,
      {
        cashtrackAccountId: d.get('cashtrackAccountId') as string | null | undefined,
        syncedThrough: (d.get('syncedThrough') as Timestamp | undefined)?.toDate(),
      },
    ]),
  );

  const result: SyncResult = { accounts: 0, imported: 0, updated: 0 };
  let context: ImportContext | undefined;

  for (const itemId of itemIds) {
    for (const account of await client.accounts(itemId)) {
      result.accounts++;
      const accountRef = user.collection('pluggy_accounts').doc(account.id);
      await accountRef.set(
        {
          itemId,
          name: account.name,
          marketingName: account.marketingName ?? null,
          type: account.type,
          subtype: account.subtype ?? null,
          number: account.number ?? null,
          balanceCents: Math.round(account.balance * 100),
          currencyCode: account.currencyCode,
          updatedAt: Timestamp.fromDate(now),
        },
        { merge: true },
      );

      const link = links.get(account.id);
      if (!importing || !link?.cashtrackAccountId) continue;

      context ??= await loadContext(user);
      const transactions = await client.transactions(
        account.id,
        syncDateFrom(link.syncedThrough, now),
      );
      const writer = db.bulkWriter();
      for (const transaction of transactions.filter(shouldImport)) {
        const docId = transactionDocId(transaction.id);
        if (context.ignored.has(docId)) continue;
        const ref = user.collection('transactions').doc(docId);
        const fields = bankFields(transaction, account, link.cashtrackAccountId);
        if (context.existing.has(docId)) {
          // Mantém a descrição e a tag que o usuário possa ter alterado.
          void writer.set(ref, fields, { merge: true });
          result.updated++;
        } else {
          void writer.set(ref, { ...fields, ...creationFields(transaction, context.tags) });
          context.existing.add(docId);
          result.imported++;
        }
      }
      await writer.close();
      await accountRef.update({ syncedThrough: Timestamp.fromDate(now) });
    }
  }
  return result;
}
