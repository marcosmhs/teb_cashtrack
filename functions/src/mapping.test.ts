import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  accountTypeFor,
  bankFields,
  creationFields,
  shouldImport,
  syncDateFrom,
  tagHistory,
  toCents,
  transactionDocId,
  transactionType,
} from './mapping';
import type { PluggyAccount, PluggyTransaction } from './pluggy';
import { nextPath } from './pluggy';

const bank: PluggyAccount = {
  id: 'acc-bank',
  itemId: 'item',
  type: 'BANK',
  name: 'Conta corrente',
  balance: 1234.56,
  currencyCode: 'BRL',
};
const card: PluggyAccount = { ...bank, id: 'acc-card', type: 'CREDIT', name: 'Cartão' };

function tx(overrides: Partial<PluggyTransaction>): PluggyTransaction {
  return {
    id: 'tx1',
    accountId: bank.id,
    date: '2026-11-10T15:30:00.000Z',
    description: 'PADARIA PÃO QUENTE',
    amount: -45.9,
    currencyCode: 'BRL',
    type: 'DEBIT',
    status: 'POSTED',
    ...overrides,
  };
}

test('centavos sem erro de arredondamento e sempre positivos', () => {
  assert.equal(toCents(-45.9), 4590);
  assert.equal(toCents(0.1 + 0.2), 30);
  assert.equal(toCents(1999.995), 200000);
});

test('tipo de conta do app', () => {
  assert.equal(accountTypeFor(bank), 'checking');
  assert.equal(accountTypeFor(card), 'creditCard');
});

test('conta bancária usa o type da Pluggy', () => {
  assert.equal(transactionType(tx({ type: 'DEBIT', amount: -10 }), bank), 'debit');
  assert.equal(transactionType(tx({ type: 'CREDIT', amount: 6500 }), bank), 'credit');
});

test('cartão usa o sinal: compra positiva é débito, pagamento negativo é crédito', () => {
  assert.equal(transactionType(tx({ amount: 89.9, type: 'DEBIT' }), card), 'debit');
  assert.equal(transactionType(tx({ amount: -1500, type: 'CREDIT' }), card), 'credit');
});

test('importa só transações confirmadas e com valor', () => {
  assert.equal(shouldImport(tx({ status: 'POSTED' })), true);
  assert.equal(shouldImport(tx({ status: undefined })), true);
  assert.equal(shouldImport(tx({ status: 'PENDING' })), false);
  assert.equal(shouldImport(tx({ amount: 0 })), false);
});

test('primeira sincronização busca 90 dias; as seguintes voltam 10 dias', () => {
  const now = new Date('2026-11-19T12:00:00Z');
  assert.equal(syncDateFrom(undefined, now), '2026-08-21');
  assert.equal(syncDateFrom(new Date('2026-11-18T12:00:00Z'), now), '2026-11-08');
});

test('ID do lançamento é fixo por transação', () => {
  assert.equal(transactionDocId('abc-123'), 'pluggy_abc-123');
});

test('campos do banco: valor, tipo, conta do app e origem', () => {
  const fields = bankFields(tx({ amount: -45.9 }), bank, 'conta-app');
  assert.equal(fields.amountCents, 4590);
  assert.equal(fields.type, 'debit');
  assert.equal(fields.accountId, 'conta-app');
  assert.equal(fields.source, 'pluggy');
  assert.equal(fields.date.toISOString(), '2026-11-10T15:30:00.000Z');
  assert.deepEqual(fields.pluggy, { id: 'tx1', accountId: 'acc-bank', description: 'PADARIA PÃO QUENTE' });
});

test('tag sugerida pela descrição mais recente igual, sem acento nem caixa', () => {
  const tags = tagHistory([
    { details: 'Padaria Pao Quente', tagId: 'antiga', date: new Date('2026-01-01') },
    { details: 'padaria pão quente!', tagId: 'alimentacao', date: new Date('2026-10-01') },
    { details: 'Mercado', tagId: null, date: new Date('2026-10-02') },
  ]);
  assert.deepEqual(creationFields(tx({}), tags), {
    details: 'PADARIA PÃO QUENTE',
    tagId: 'alimentacao',
  });
  assert.deepEqual(creationFields(tx({ description: 'Posto' }), tags), {
    details: 'Posto',
    tagId: null,
  });
  assert.deepEqual(creationFields(tx({ description: '  ' }), tags), { details: null, tagId: null });
});

test('próxima página da v2: query string, URL completa ou cursor solto', () => {
  assert.equal(nextPath('?after=abc&accountId=x', 'x', '2026-01-01'), '/v2/transactions?after=abc&accountId=x');
  assert.equal(
    nextPath('https://api.pluggy.ai/v2/transactions?after=abc', 'x', '2026-01-01'),
    '/v2/transactions?after=abc',
  );
  assert.equal(
    nextPath('abc', 'x', '2026-01-01'),
    '/v2/transactions?accountId=x&dateFrom=2026-01-01&after=abc',
  );
});
