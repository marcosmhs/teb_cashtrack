import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/account_controller.dart';
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
import '../services/notification_capture_service.dart';
import 'notification_settings_view.dart';
import 'transaction_filter_view.dart';
import 'transaction_statement_view.dart';
import 'user_edit_view.dart';

class _HomeData {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final Map<String, String> tagNames;

  _HomeData(this.accounts, this.transactions, List<Tag> tags)
    : tagNames = {for (final t in tags) t.id: t.name};
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Um único stream combinado, criado uma vez: evita assinaturas duplicadas
  // e o "piscar" de carregamento a cada reconstrução.
  /// No Android, indica se o lançamento automático ainda precisa de permissão.
  bool _notificationAccessPending = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationAccess();
  }

  Future<void> _checkNotificationAccess() async {
    if (!NotificationCaptureService.isSupported) return;
    try {
      final status = await NotificationCaptureService().getStatus();
      if (mounted) setState(() => _notificationAccessPending = !status.permissionGranted);
    } catch (e) {
      debugPrint('Erro ao verificar acesso às notificações: $e');
    }
  }

  Future<void> _openNotificationSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationSettingsView()));
    _checkNotificationAccess();
  }

  late final Stream<_HomeData> _data = Rx.combineLatest3(
    AccountController().getAccounts(),
    TransactionController().getTransactions(),
    TagController().getTags(),
    _HomeData.new,
  );

  /// Garante que o formulário abra sozinho apenas uma vez por sessão.
  bool _autoOpenedForm = false;

  /// Ao abrir o app, já exibe o formulário de novo lançamento (evita um clique),
  /// desde que exista ao menos uma conta ativa para lançar.
  void _autoOpenFormOnce(_HomeData data) {
    if (_autoOpenedForm || !data.accounts.any((a) => a.active)) return;
    _autoOpenedForm = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showTransactionForm(context);
    });
  }

  void _openStatement(Account account) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TransactionStatementView(account: account)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CashTrack', style: context.text.headlineMedium),
        actions: [
          if (NotificationCaptureService.isSupported)
            IconButton(
              icon: const Icon(Icons.bolt_outlined),
              tooltip: 'Lançamento automático',
              onPressed: _openNotificationSettings,
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar lançamentos',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TransactionFilterView())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Dados do usuário',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserEditView())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTransactionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Lançamento'),
      ),
      body: StreamBuilder<_HomeData>(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          _autoOpenFormOnce(data);
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(_HomeData data) {
    final active = data.accounts.where((a) => a.active).toList();
    final cards = active.where((a) => a.isCreditCard).toList();
    final otherAccounts = active.where((a) => !a.isCreditCard).toList();

    if (data.accounts.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Bem-vindo ao CashTrack!',
        message: 'Comece cadastrando uma conta ou cartão na aba Contas.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.xs, 20, 96),
      child: ResponsiveBody(
        maxWidth: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_notificationAccessPending) ...[
              Card(
                color: context.colors.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.bolt),
                  title: const Text('Ative o lançamento automático'),
                  subtitle: const Text(
                    'Crie lançamentos a partir das notificações do Samsung Wallet.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openNotificationSettings,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final balance = _buildBalanceCard(otherAccounts, data.transactions);
                final cardsCard = _buildCardsCard(cards, data.transactions);
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      balance,
                      const SizedBox(height: AppSpacing.md),
                      cardsCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: balance),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: cardsCard),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentTransactions(data),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(List<Account> accounts, List<Transaction> transactions) {
    final checking = accounts.where((a) => a.type == AccountType.checking);
    final total = BalanceCalculator.totalBalance(checking, transactions);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo em contas correntes',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          AmountText(total, style: context.text.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Nenhuma conta ativa.',
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          for (final account in accounts)
            _AccountRow(
              name: account.name,
              subtitle: account.type.label,
              cents: BalanceCalculator.accountBalance(account, transactions),
              onTap: () => _openStatement(account),
            ),
        ],
      ),
    );
  }

  Widget _buildCardsCard(List<Account> cards, List<Transaction> transactions) {
    final now = DateTime.now();
    final invoices = {
      for (final c in cards) c.id: BalanceCalculator.currentInvoice(c, transactions, now),
    };
    final total = invoices.values.fold(0, (a, b) => a + b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Faturas abertas dos cartões',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          // Fatura é valor a pagar: exibida como negativo no saldo do usuário.
          AmountText(-total, style: context.text.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Nenhum cartão de crédito ativo.',
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          for (final card in cards)
            _AccountRow(
              name: card.name,
              subtitle: card.closingDay == null
                  ? 'Defina o dia de fechamento'
                  : 'Fecha em ${formatDate(BalanceCalculator.currentInvoicePeriod(card.closingDay, now).end)}',
              cents: -invoices[card.id]!,
              onTap: () => _openStatement(card),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(_HomeData data) {
    final accountNames = {for (final a in data.accounts) a.id: a.name};
    final recent = data.transactions.take(5).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, AppSpacing.xs, AppSpacing.xs),
            child: SectionHeader(
              title: 'Últimos lançamentos',
              trailing: TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TransactionFilterView())),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver todos'),
              ),
            ),
          ),
          const Divider(),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Nenhum lançamento ainda. Toque em "Lançamento" para começar.'),
            ),
          for (final (i, t) in recent.indexed) ...[
            if (i > 0) const Divider(indent: 20, endIndent: 20),
            TransactionTile(
              transaction: t,
              accountName: accountNames[t.accountId],
              tagName: data.tagNames[t.tagId],
              onTap: () => showTransactionForm(context, transaction: t),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.subtitle,
    required this.cents,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final int cents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            AmountText(cents, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: context.colors.onSurfaceVariant,
              semanticLabel: 'Ver extrato',
            ),
          ],
        ),
      ),
    );
  }
}
