/// Como os lançamentos chegam ao app sem serem digitados.
///
/// Gravado em `users/{uid}/settings/import`, campo `mode`, e lido também pelo
/// serviço de notificações (Kotlin) e pela sincronização da Pluggy (functions/),
/// para valer em todos os aparelhos.
enum ImportMode {
  manual('manual', 'Só manual', 'Você digita todos os lançamentos.'),
  notifications(
    'notifications',
    'Notificações do celular',
    'Lê as notificações de pagamento no Android e cria o lançamento na hora.',
  ),
  pluggy(
    'pluggy',
    'Banco (Pluggy)',
    'Importa contas e transações do banco pelo Open Finance, algumas vezes por dia.',
  );

  const ImportMode(this.storageKey, this.label, this.description);

  final String storageKey;
  final String label;
  final String description;

  /// Sem configuração gravada vale o comportamento anterior: notificações.
  static ImportMode parse(Object? value) => ImportMode.values.firstWhere(
    (m) => m.storageKey == value,
    orElse: () => ImportMode.notifications,
  );
}

class ImportSettings {
  const ImportSettings._();

  /// Documento em `users/{uid}/settings`.
  static const docId = 'import';
  static const modeField = 'mode';
}
