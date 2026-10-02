import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/tag_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/tag.dart';
import '../models/transaction.dart';
import '../services/balance_calculator.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

class TransactionStatementView extends StatefulWidget {
  const TransactionStatementView({super.key, required this.account});

  final Account account;

  @override
  State<TransactionStatementView> createState() => _TransactionStatementViewState();
}

class _TransactionStatementViewState extends State<TransactionStatementView> {
  late final Stream<(List<Transaction>, Map<String, String>)> _data = Rx.combineLatest2(
    TransactionController().getTransactionsForAccount(widget.account.id),
    TagController().getTags(),
    (List<Transaction> txs, List<Tag> tags) => (txs, {for (final t in tags) t.id: t.name}),
  );

  /// Para cartões: exibir só a fatura aberta (padrão) ou todo o histórico.
  bool _onlyCurrentInvoice = true;

  Account get account => widget.account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Extrato · ${account.name}')),
      body: StreamBuilder(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          final (allTxs, tagNames) = data;

          final period = BalanceCalculator.currentInvoicePeriod(account.closingDay, DateTime.now());
          final showInvoice = account.isCreditCard && _onlyCurrentInvoice;
          final txs = showInvoice ? allTxs.where((t) => period.contains(t.date)).toList() : allTxs;

          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                _buildSummary(allTxs, period),
                if (account.isCreditCard) ...[
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Fatura atual')),
                      ButtonSegment(value: false, label: Text('Todos')),
                    ],
                    selected: {_onlyCurrentInvoice},
                    onSelectionChanged: (s) => setState(() => _onlyCurrentInvoice = s.first),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (txs.isEmpty)
                  const EmptyState(icon: Icons.receipt_long_outlined, title: 'Nenhum lançamento.')
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, t) in txs.indexed) ...[
                          if (i > 0) const Divider(indent: 20, endIndent: 20),
                          TransactionTile(
                            transaction: t,
                            tagName: tagNames[t.tagId],
                            onTap: () => showTransactionForm(context, transaction: t),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(List<Transaction> txs, InvoicePeriod period) {
    final muted = context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);

    if (account.isCreditCard) {
      final invoice = BalanceCalculator.currentInvoice(account, txs, DateTime.now());
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fatura atual', style: muted),
            const SizedBox(height: 4),
            AmountText(-invoice, style: context.text.headlineMedium),
            const SizedBox(height: 4),
            Text(
              account.closingDay == null
                  ? 'Sem dia de fechamento definido: considerando todos os lançamentos.'
                  : '${formatDate(period.start!.add(const Duration(days: 1)))} a ${formatDate(period.end)}',
              style: muted,
            ),
          ],
        ),
      );
    }

    final balance = BalanceCalculator.accountBalance(account, txs);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo atual', style: muted),
          const SizedBox(height: 4),
          AmountText(balance, style: context.text.headlineMedium),
          if (account.initialBalanceCents != 0) ...[
            const SizedBox(height: 4),
            Text(
              'Inclui saldo inicial de ${formatCents(account.initialBalanceCents)}',
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}
