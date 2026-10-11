import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/account_controller.dart';
import '../controllers/tag_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/tag.dart';
import '../models/transaction.dart';
import '../services/tag_stats.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _monthLabel(DateTime month) => '${_months[month.month - 1]} de ${month.year}';

class _SpendingData {
  final List<Transaction> transactions;
  final Map<String, String> tagNames;

  _SpendingData(this.transactions, List<Tag> tags)
    : tagNames = {for (final t in tags) t.id: t.name};
}

/// Total do mês agrupado por tag, com drill-down nos lançamentos de cada tag.
class TagSpendingView extends StatefulWidget {
  const TagSpendingView({super.key});

  @override
  State<TagSpendingView> createState() => _TagSpendingViewState();
}

class _TagSpendingViewState extends State<TagSpendingView> {
  final _txController = TransactionController();
  late final Stream<List<Tag>> _tags = TagController().getTags();
  late Stream<_SpendingData> _data;

  late DateTime _month;
  TransactionType _type = TransactionType.debit;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _subscribe();
  }

  /// O mês é filtrado no Firestore; o agrupamento é feito no app.
  void _subscribe() {
    _data = Rx.combineLatest2(
      _txController.getTransactionsInRange(
        from: _month,
        to: DateTime(_month.year, _month.month + 1, 0),
      ),
      _tags,
      _SpendingData.new,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _subscribe();
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  String _tagLabel(_SpendingData data, String? tagId) =>
      tagId == null ? 'Sem tag' : data.tagNames[tagId] ?? 'Tag excluída';

  void _openTag(_SpendingData data, TagTotal total) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TagTransactionsView(
          title: _tagLabel(data, total.tagId),
          month: _month,
          tagId: total.tagId,
          type: _type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos por tag')),
      body: StreamBuilder<_SpendingData>(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                _buildMonthSelector(),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.debit, label: Text('Despesas')),
                    ButtonSegment(value: TransactionType.credit, label: Text('Receitas')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
                if (data == null) const LoadingView() else ..._buildContent(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mês anterior',
        ),
        Expanded(
          child: Text(
            _monthLabel(_month),
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
        ),
        IconButton(
          onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Próximo mês',
        ),
      ],
    );
  }

  List<Widget> _buildContent(_SpendingData data) {
    final totals = TagStats.totalsByTag(data.transactions, _type);
    final grandTotal = totals.fold(0, (sum, t) => sum + t.cents);
    final isExpense = _type == TransactionType.debit;
    final muted = context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);

    if (totals.isEmpty) {
      return [
        EmptyState(
          icon: Icons.insights_outlined,
          title: isExpense ? 'Nenhuma despesa neste mês.' : 'Nenhuma receita neste mês.',
        ),
      ];
    }

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isExpense ? 'Total de despesas' : 'Total de receitas', style: muted),
            const SizedBox(height: 4),
            Text(
              formatCents(grandTotal),
              style: context.text.headlineLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${totals.fold(0, (sum, t) => sum + t.count)} lançamento(s) em '
              '${totals.length} ${totals.length == 1 ? 'tag' : 'tags'}',
              style: muted,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, total) in totals.indexed) ...[
              if (i > 0) const Divider(),
              TagBarRow(
                label: _tagLabel(data, total.tagId),
                total: total,
                // Barras relativas à maior tag: a primeira ocupa a largura toda.
                fraction: total.cents / totals.first.cents,
                share: total.cents / grandTotal,
                muted: total.tagId == null,
                onTap: () => _openTag(data, total),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

/// Linha do ranking: nome, valor, participação e barra proporcional.
class TagBarRow extends StatelessWidget {
  const TagBarRow({
    required this.label,
    required this.total,
    required this.fraction,
    required this.share,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final TagTotal total;
  final double fraction;
  final double share;

  /// "Sem tag" usa cor neutra para não competir com as tags.
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (share * 100).round();
    final secondary = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final barColor = muted ? context.colors.outline : context.colors.primary;

    return Semantics(
      button: true,
      label: '$label: ${formatCents(total.cents)}, $percent por cento, ${total.count} lançamentos',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontStyle: muted ? FontStyle.italic : null,
                            ),
                          ),
                        ),
                        Text(
                          formatCents(total.cents),
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          // Largura mínima para valores muito pequenos continuarem visíveis.
                          width: (constraints.maxWidth * fraction).clamp(4.0, constraints.maxWidth),
                          height: 8,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$percent% · ${total.count} lançamento${total.count == 1 ? '' : 's'}',
                      style: secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lançamentos de uma tag no mês selecionado, atualizados em tempo real.
class _TagTransactionsView extends StatefulWidget {
  const _TagTransactionsView({
    required this.title,
    required this.month,
    required this.tagId,
    required this.type,
  });

  final String title;
  final DateTime month;
  final String? tagId;
  final TransactionType type;

  @override
  State<_TagTransactionsView> createState() => _TagTransactionsViewState();
}

class _TagTransactionsViewState extends State<_TagTransactionsView> {
  late final Stream<(List<Transaction>, Map<String, String>)> _data = Rx.combineLatest2(
    TransactionController().getTransactionsInRange(
      from: widget.month,
      to: DateTime(widget.month.year, widget.month.month + 1, 0),
    ),
    AccountController().getAccounts(),
    (List<Transaction> txs, List<Account> accounts) => (
      txs.where((t) => t.type == widget.type && t.tagId == widget.tagId).toList(),
      {for (final a in accounts) a.id: a.name},
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              _monthLabel(widget.month),
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          final (transactions, accountNames) = data;
          if (transactions.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Nenhum lançamento.');
          }
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, t) in transactions.indexed) ...[
                        if (i > 0) const Divider(indent: 20, endIndent: 20),
                        TransactionTile(
                          transaction: t,
                          accountName: accountNames[t.accountId],
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
}
