import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/account_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/balance_calculator.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account_form_view.dart';
import 'transaction_statement_view.dart';

class AccountListView extends StatefulWidget {
  const AccountListView({super.key});

  @override
  State<AccountListView> createState() => _AccountListViewState();
}

class _AccountListViewState extends State<AccountListView> {
  late final Stream<(List<Account>, List<Transaction>)> _data = Rx.combineLatest2(
    AccountController().getAccounts(),
    TransactionController().getTransactions(),
    (List<Account> a, List<Transaction> t) => (a, t),
  );

  void _openForm([Account? account]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AccountFormView(account: account)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contas e cartões')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nova conta'),
      ),
      body: StreamBuilder(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          final (accounts, transactions) = data;

          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nenhuma conta cadastrada ainda.',
              message:
                  'Cadastre contas correntes, cartões e investimentos para acompanhar seus saldos.',
              action: FilledButton(onPressed: _openForm, child: const Text('Cadastrar conta')),
            );
          }

          // Ativas primeiro; dentro de cada grupo, ordem alfabética (vinda do Firestore).
          final sorted = [...accounts.where((a) => a.active), ...accounts.where((a) => !a.active)];
          final now = DateTime.now();

          return ResponsiveBody(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final account = sorted[i];
                final cents = account.isCreditCard
                    ? -BalanceCalculator.currentInvoice(account, transactions, now)
                    : BalanceCalculator.accountBalance(account, transactions);
                return _AccountCard(
                  account: account,
                  cents: cents,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TransactionStatementView(account: account)),
                  ),
                  onEdit: () => _openForm(account),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.cents,
    required this.onTap,
    required this.onEdit,
  });

  final Account account;
  final int cents;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  IconData get _icon => switch (account.type) {
    AccountType.checking => Icons.account_balance_outlined,
    AccountType.creditCard => Icons.credit_card,
    AccountType.investment => Icons.trending_up,
  };

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Opacity(
      opacity: account.active ? 1 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.colors.secondaryContainer,
                  foregroundColor: context.colors.onSecondaryContainer,
                  child: Icon(_icon),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: context.text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        [
                          account.type.label,
                          if (account.isCreditCard && account.closingDay != null)
                            'fecha dia ${account.closingDay}',
                          if (!account.active) 'inativa',
                        ].join(' · '),
                        style: muted,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(cents),
                    Text(account.isCreditCard ? 'fatura atual' : 'saldo', style: muted),
                  ],
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar ${account.name}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
