/**
 * Cliente mínimo da API da Pluggy (https://docs.pluggy.ai).
 * Só leitura: contas e transações de itens já conectados pelo Meu Pluggy.
 */

const BASE_URL = 'https://api.pluggy.ai';

export interface PluggyAccount {
  id: string;
  itemId: string;
  type: 'BANK' | 'CREDIT';
  subtype?: string | null;
  name: string;
  marketingName?: string | null;
  /** Conta bancária: número da conta. Cartão: os 4 últimos dígitos. */
  number?: string | null;
  /** Conta bancária: saldo disponível. Cartão: valor da fatura em aberto. */
  balance: number;
  currencyCode: string;
}

export interface PluggyTransaction {
  id: string;
  accountId: string;
  /** ISO 8601, em UTC. */
  date: string;
  description: string;
  /** Em cartões, positivo é compra e negativo é pagamento/estorno. */
  amount: number;
  currencyCode: string;
  type: 'DEBIT' | 'CREDIT';
  status?: 'PENDING' | 'POSTED' | null;
}

type Fetch = typeof fetch;

export class PluggyError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message);
  }
}

export class PluggyClient {
  private apiKey?: string;

  constructor(
    private readonly clientId: string,
    private readonly clientSecret: string,
    private readonly fetchImpl: Fetch = fetch,
  ) {}

  /** A chave vale 2 horas; uma execução da sincronização usa uma só. */
  private async key(): Promise<string> {
    if (this.apiKey) return this.apiKey;
    const response = await this.fetchImpl(`${BASE_URL}/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ clientId: this.clientId, clientSecret: this.clientSecret }),
    });
    if (!response.ok) {
      throw new PluggyError(`Falha na autenticação da Pluggy (HTTP ${response.status})`, response.status);
    }
    const body = (await response.json()) as { apiKey?: string };
    if (!body.apiKey) throw new PluggyError('A Pluggy não devolveu a chave de acesso');
    this.apiKey = body.apiKey;
    return body.apiKey;
  }

  private async get<T>(pathAndQuery: string): Promise<T> {
    const response = await this.fetchImpl(`${BASE_URL}${pathAndQuery}`, {
      headers: { 'X-API-KEY': await this.key(), Accept: 'application/json' },
    });
    if (!response.ok) {
      const path = pathAndQuery.split('?')[0];
      throw new PluggyError(`Erro da Pluggy em ${path} (HTTP ${response.status})`, response.status);
    }
    return (await response.json()) as T;
  }

  async accounts(itemId: string): Promise<PluggyAccount[]> {
    const all: PluggyAccount[] = [];
    for (let page = 1; ; page++) {
      const query = new URLSearchParams({ itemId, page: String(page), pageSize: '500' });
      const body = await this.get<{ results: PluggyAccount[]; totalPages?: number }>(
        `/accounts?${query}`,
      );
      all.push(...body.results);
      if (!body.totalPages || page >= body.totalPages) return all;
    }
  }

  /**
   * Transações da conta a partir de [dateFrom] (yyyy-mm-dd), seguindo o cursor do
   * `GET /v2/transactions` até `next` ser nulo. O `/transactions` antigo (v1) deixa
   * de existir em 31/12/2026.
   */
  async transactions(accountId: string, dateFrom: string): Promise<PluggyTransaction[]> {
    const all: PluggyTransaction[] = [];
    let path = `/v2/transactions?${new URLSearchParams({ accountId, dateFrom })}`;
    for (let guard = 0; guard < 1000; guard++) {
      const body = await this.get<{ results: PluggyTransaction[]; next?: string | null }>(path);
      all.push(...body.results);
      if (!body.next) return all;
      path = nextPath(body.next, accountId, dateFrom);
    }
    throw new PluggyError('Paginação de transações da Pluggy não terminou');
  }
}

/**
 * A documentação descreve `next` como a query string pronta para a próxima página;
 * o SDK oficial também aceita um cursor solto ou uma URL completa. Cobre os três.
 */
export function nextPath(next: string, accountId: string, dateFrom: string): string {
  if (next.startsWith('?')) return `/v2/transactions${next}`;
  if (next.startsWith('http')) {
    const url = new URL(next);
    return `${url.pathname}${url.search}`;
  }
  if (next.startsWith('/')) return next;
  return `/v2/transactions?${new URLSearchParams({ accountId, dateFrom, after: next })}`;
}
