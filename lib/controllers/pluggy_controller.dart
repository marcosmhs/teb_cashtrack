import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:cloud_functions/cloud_functions.dart';

import '../data/local_first.dart';
import '../data/user_collections.dart';
import '../models/account.dart';
import '../models/pluggy.dart';
import '../models/transaction.dart';
import 'account_controller.dart';

class PluggyController {
  /// Região das funções em functions/src/index.ts.
  static const functionsRegion = 'southamerica-east1';

  JsonCollection get _accounts => UserCollections.of(UserCollections.pluggyAccounts);

  /// `null` enquanto a Pluggy não estiver configurada para este usuário no servidor.
  Stream<PluggyStatus?> watchStatus() {
    return UserCollections.of(UserCollections.settings).doc(PluggyStatus.docId).snapshots().map((
      s,
    ) {
      final data = s.data();
      return data == null ? null : PluggyStatus.fromMap(data);
    });
  }

  Stream<List<PluggyAccount>> watchAccounts() {
    return _accounts.snapshots().map((s) {
      final accounts = s.docs.map((d) => PluggyAccount.fromMap(d.data(), d.id)).toList();
      accounts.sort((a, b) => a.displayName.compareTo(b.displayName));
      return accounts;
    });
  }

  /// Define a conta do app que recebe os lançamentos ([cashtrackAccountId] `null` para
  /// parar de importar). Ao trocar de conta, a importação recomeça do zero (90 dias),
  /// o que também move os lançamentos já importados para a conta nova.
  Future<void> link(PluggyAccount account, String? cashtrackAccountId) {
    return writeLocal(
      _accounts.doc(account.id).update({
        PluggyAccount.cashtrackAccountIdField: cashtrackAccountId,
        PluggyAccount.syncedThroughField: FieldValue.delete(),
      }),
      'o vínculo da conta',
    );
  }

  /// Cria no app uma conta com o nome e o tipo da conta do banco e a vincula.
  Future<void> createAndLink(PluggyAccount account) async {
    final accountController = AccountController();
    final id = accountController.newId();
    await accountController.saveAccount(
      Account(
        id: id,
        name: account.displayName,
        type: account.appType,
        initialBalanceCents: 0,
        active: true,
        createdAt: DateTime.now(),
      ),
    );
    await link(account, id);
  }

  /// Pede ao servidor uma sincronização agora. Precisa de internet.
  /// Retorna a quantidade de lançamentos novos.
  Future<int> syncNow() async {
    final result = await FirebaseFunctions.instanceFor(
      region: functionsRegion,
    ).httpsCallable('pluggySyncNow').call<Map<String, dynamic>>();
    return (result.data['imported'] as num?)?.toInt() ?? 0;
  }

  /// Saldo inicial que faz o saldo da conta no app ficar igual ao do banco,
  /// considerando os lançamentos que já estão no app.
  static int initialBalanceToMatch(
    int bankBalanceCents,
    String accountId,
    Iterable<Transaction> transactions,
  ) {
    final sum = transactions
        .where((t) => t.accountId == accountId)
        .fold(0, (total, t) => total + t.signedCents);
    return bankBalanceCents - sum;
  }
}
