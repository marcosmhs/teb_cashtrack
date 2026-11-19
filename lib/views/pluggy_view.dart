import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/account_controller.dart';
import '../controllers/import_settings_controller.dart';
import '../controllers/pluggy_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/import_settings.dart';
import '../models/pluggy.dart';
import '../models/transaction.dart';
import '../services/balance_calculator.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class _PluggyData {
  final ImportMode mode;
  final PluggyStatus? status;
  final List<PluggyAccount> bankAccounts;
  final List<Account> appAccounts;
  final List<Transaction> transactions;

  _PluggyData(this.mode, this.status, this.bankAccounts, this.appAccounts, this.transactions);
}

/// Contas do banco trazidas pela Pluggy: vincular cada uma a uma conta do app,
/// sincronizar agora e conferir o saldo.
class PluggyView extends StatefulWidget {
  const PluggyView({super.key});

  @override
  State<PluggyView> createState() => _PluggyViewState();
}

class _PluggyViewState extends State<PluggyView> {
  static const _createAccount = '__nova__';

  final _pluggy = PluggyController();
  bool _syncing = false;

  late final Stream<_PluggyData> _data = Rx.combineLatest5(
    ImportSettingsController().watchMode(),
    _pluggy.watchStatus(),
    _pluggy.watchAccounts(),
    AccountController().getAccounts(),
    TransactionController().getTransactions(),
    _PluggyData.new,
  );

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final imported = await _pluggy.syncNow();
      if (mounted) {
        showMessage(
          context,
          imported == 0 ? 'Nada novo no banco.' : '$imported lançamento(s) novo(s) do banco.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Erro ao sincronizar com a Pluggy: ${e.code} ${e.message}');
      if (mounted) {
        showMessage(
          context,
          e.code == 'unavailable'
              ? 'Sem conexão. Tente de novo quando estiver on-line.'
              : e.message ?? 'Não foi possível sincronizar.',
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _link(PluggyAccount account, String? value) async {
    if (value == _createAccount) {
      await _pluggy.createAndLink(account);
    } else {
      await _pluggy.link(account, value);
    }
    if (mounted && value != null) {
      showMessage(context, 'Conta vinculada. Toque em "Sincronizar agora" para importar.');
    }
  }

  Future<void> _matchBalance(PluggyAccount bank, Account app, List<Transaction> txs) async {
    final initial = PluggyController.initialBalanceToMatch(bank.balanceCents, app.id, txs);
    final confirmed = await confirmAction(
      context,
      title: 'Igualar saldo ao banco?',
      message:
          'O saldo inicial de "${app.name}" passa a ser ${formatCents(initial)}, '
          'para o saldo no app ficar igual ao do banco (${formatCents(bank.balanceCents)}).',
      confirmLabel: 'Igualar',
    );
    if (!confirmed) return;
    await AccountController().saveAccount(
      Account(
        id: app.id,
        name: app.name,
        type: app.type,
        initialBalanceCents: initial,
        active: app.active,
        createdAt: app.createdAt,
        closingDay: app.closingDay,
        isDefault: app.isDefault,
        notificationMatch: app.notificationMatch,
      ),
    );
    if (mounted) showMessage(context, 'Saldo ajustado.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contas do banco (Pluggy)')),
      body: StreamBuilder<_PluggyData>(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          if (data.status == null) {
            return const EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'Pluggy não configurada para esta conta.',
              message: 'A integração usa as credenciais do Meu Pluggy configuradas no servidor.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ResponsiveBody(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.mode != ImportMode.pluggy) ...[
                      Card(
                        color: context.colors.secondaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('A importação está desligada'),
                          subtitle: const Text(
                            'Os lançamentos do banco só entram no app com o modo '
                            '"Banco (Pluggy)" escolhido em Lançamento automático.',
                          ),
                          trailing: TextButton(
                            onPressed: () => ImportSettingsController().setMode(ImportMode.pluggy),
                            child: const Text('Ativar'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildStatusCard(data.status!),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Contas no banco', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Escolha em qual conta do app entram os lançamentos de cada conta do banco. '
                      'Na primeira vez são importados os últimos 90 dias.',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (data.bankAccounts.isEmpty)
                      const EmptyState(
                        icon: Icons.sync,
                        title: 'Nenhuma conta ainda.',
                        message: 'Toque em "Sincronizar agora" para buscar as contas do banco.',
                      ),
                    for (final bank in data.bankAccounts) ...[
                      _buildAccountCard(bank, data),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(PluggyStatus status) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final lastSync = status.lastSyncAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                status.hasError ? Icons.error_outline : Icons.cloud_done_outlined,
                color: status.hasError ? context.colors.error : context.finance.income,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  lastSync == null
                      ? 'Ainda não sincronizado'
                      : 'Última sincronização: ${formatDate(lastSync)} '
                            '${lastSync.hour.toString().padLeft(2, '0')}:'
                            '${lastSync.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),
          if (status.hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(status.lastError!, style: muted?.copyWith(color: context.colors.error)),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'O servidor sincroniza sozinho às 7h, 13h e 19h. O Meu Pluggy atualiza os dados '
            'do banco uma vez por dia.',
            style: muted,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: const Text('Sincronizar agora'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(PluggyAccount bank, _PluggyData data) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final compatible = data.appAccounts.where(
      (a) => a.type == bank.appType || a.id == bank.cashtrackAccountId,
    );
    final linked = data.appAccounts.where((a) => a.id == bank.cashtrackAccountId).firstOrNull;
    final appBalance = linked == null || bank.isCreditCard
        ? null
        : BalanceCalculator.accountBalance(linked, data.transactions);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(bank.appType.icon, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bank.displayName, style: context.text.titleSmall),
                    Text([bank.appType.label, ?bank.numberLabel].join(' · '), style: muted),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCents(bank.balanceCents), style: context.text.titleSmall),
                  Text(bank.isCreditCard ? 'fatura no banco' : 'saldo no banco', style: muted),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            // Recria o campo quando o vínculo muda no Firestore (ex.: após "Criar conta").
            key: ValueKey('${bank.id}:${linked?.id}'),
            value: linked?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Lançamentos vão para'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Não importar')),
              for (final a in compatible)
                DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name, overflow: TextOverflow.ellipsis),
                ),
              const DropdownMenuItem(value: _createAccount, child: Text('Criar conta no app')),
            ],
            onChanged: (value) => _link(bank, value),
          ),
          if (linked != null && bank.syncedThrough != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Importado até ${formatDate(bank.syncedThrough!)}', style: muted),
          ],
          if (appBalance != null && appBalance != bank.balanceCents) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: Text('Saldo no app: ${formatCents(appBalance)}', style: muted)),
                TextButton(
                  onPressed: () => _matchBalance(bank, linked!, data.transactions),
                  child: const Text('Igualar ao banco'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
