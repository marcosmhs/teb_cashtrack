/**
 * Conversão dos dados da Pluggy para o formato do CashTrack (ver lib/models/ no app).
 * Funções puras, cobertas por mapping.test.ts.
 */
import type { PluggyAccount, PluggyTransaction } from './pluggy';

/** Igual a `Transaction.sourcePluggy` no app. */
export const SOURCE_PLUGGY = 'pluggy';

/** Histórico importado na primeira sincronização de uma conta. */
export const INITIAL_DAYS = 90;

/**
 * Nas sincronizações seguintes, volta alguns dias antes da última para pegar
 * lançamentos que o banco publica com atraso. Reimportar é seguro: o ID é fixo.
 */
export const OVERLAP_DAYS = 10;

const DAY_MS = 24 * 60 * 60 * 1000;

export function toCents(amount: number): number {
  return Math.round(Math.abs(amount) * 100);
}

/** Tipo de conta do app (`AccountType.storageKey`) para uma conta da Pluggy. */
export function accountTypeFor(account: Pick<PluggyAccount, 'type'>): 'checking' | 'creditCard' {
  return account.type === 'CREDIT' ? 'creditCard' : 'checking';
}

/** ID do lançamento no Firestore: fixo por transação, então sincronizar de novo não duplica. */
export function transactionDocId(pluggyTransactionId: string): string {
  return `pluggy_${pluggyTransactionId}`;
}

/**
 * Débito ou crédito no app. Em cartões a Pluggy indica pelo sinal (compra positiva,
 * pagamento ou estorno negativo); em contas bancárias, pelo `type`.
 */
export function transactionType(
  transaction: Pick<PluggyTransaction, 'amount' | 'type'>,
  account: Pick<PluggyAccount, 'type'>,
): 'debit' | 'credit' {
  if (account.type === 'CREDIT') return transaction.amount >= 0 ? 'debit' : 'credit';
  return transaction.type === 'CREDIT' ? 'credit' : 'debit';
}

/** Só transações confirmadas: as pendentes podem mudar de ID ou sumir no banco. */
export function shouldImport(transaction: Pick<PluggyTransaction, 'status' | 'amount'>): boolean {
  return transaction.status !== 'PENDING' && transaction.amount !== 0;
}

/** Primeiro dia (yyyy-mm-dd) a buscar na Pluggy para uma conta. */
export function syncDateFrom(syncedThrough: Date | undefined, now: Date): string {
  const from = syncedThrough
    ? new Date(syncedThrough.getTime() - OVERLAP_DAYS * DAY_MS)
    : new Date(now.getTime() - INITIAL_DAYS * DAY_MS);
  return from.toISOString().slice(0, 10);
}

/** Chave para reconhecer a mesma descrição em lançamentos diferentes. */
export function normalizeDescription(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

export interface TaggedTransaction {
  details?: string | null;
  tagId?: string | null;
  date: Date;
}

/** Descrição normalizada → tag usada no lançamento mais recente com essa descrição. */
export function tagHistory(transactions: TaggedTransaction[]): Map<string, string> {
  const latest = new Map<string, { tagId: string; date: number }>();
  for (const t of transactions) {
    if (!t.details || !t.tagId) continue;
    const key = normalizeDescription(t.details);
    if (!key) continue;
    const current = latest.get(key);
    if (!current || t.date.getTime() > current.date) {
      latest.set(key, { tagId: t.tagId, date: t.date.getTime() });
    }
  }
  return new Map([...latest].map(([key, value]) => [key, value.tagId]));
}

/** Campos que a sincronização sempre atualiza (o banco é a fonte da verdade). */
export interface BankFields {
  date: Date;
  accountId: string;
  amountCents: number;
  type: 'debit' | 'credit';
  source: typeof SOURCE_PLUGGY;
  pluggy: { id: string; accountId: string; description: string };
}

/** Campos gravados só na criação: depois o usuário pode trocar a descrição e a tag. */
export interface CreationFields {
  details: string | null;
  tagId: string | null;
}

export function bankFields(
  transaction: PluggyTransaction,
  account: PluggyAccount,
  cashtrackAccountId: string,
): BankFields {
  return {
    date: new Date(transaction.date),
    accountId: cashtrackAccountId,
    amountCents: toCents(transaction.amount),
    type: transactionType(transaction, account),
    source: SOURCE_PLUGGY,
    pluggy: { id: transaction.id, accountId: account.id, description: transaction.description },
  };
}

export function creationFields(
  transaction: PluggyTransaction,
  tags: Map<string, string>,
): CreationFields {
  const details = transaction.description?.trim() || null;
  return {
    details,
    tagId: details ? (tags.get(normalizeDescription(details)) ?? null) : null,
  };
}
