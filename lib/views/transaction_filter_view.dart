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
import '../widgets/common.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

class _FilterData {
  final List<Account> accounts;
  final List<Tag> tags;
  final List<Transaction> transactions;

  _FilterData(this.accounts, this.tags, this.transactions);
}

class TransactionFilterView extends StatefulWidget {
  const TransactionFilterView({super.key});

  @override
  State<TransactionFilterView> createState() => _TransactionFilterViewState();
}

class _TransactionFilterViewState extends State<TransactionFilterView> {
  final _txController = TransactionController();
  late final Stream<List<Account>> _accounts = AccountController().getAccounts();
  late final Stream<List<Tag>> _tags = TagController().getTags();
  late Stream<_FilterData> _data;

  final _searchController = TextEditingController();
  String? _accountId;
  TransactionType? _type;
  String? _tagId;
  late DateTime? _fromDate;
  late DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _setCurrentMonth();
    _subscribe();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month);
    _toDate = DateTime(now.year, now.month + 1, 0);
  }

  /// O período é filtrado no Firestore (evita baixar todo o histórico);
  /// os demais filtros são aplicados localmente, em tempo real.
  void _subscribe() {
    _data = Rx.combineLatest3(
      _accounts,
      _tags,
      _txController.getTransactionsInRange(from: _fromDate, to: _toDate),
      _FilterData.new,
    );
  }

  void _setPeriod({DateTime? from, DateTime? to, bool clearFrom = false, bool clearTo = false}) {
    setState(() {
      _fromDate = clearFrom ? null : (from ?? _fromDate);
      _toDate = clearTo ? null : (to ?? _toDate);
      _subscribe();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _accountId = null;
      _type = null;
      _tagId = null;
      _setCurrentMonth();
      _subscribe();
    });
  }

  bool _matches(Transaction tx) {
    if (_accountId != null && tx.accountId != _accountId) return false;
    if (_type != null && tx.type != _type) return false;
    if (_tagId != null && tx.tagId != _tagId) return false;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty && !(tx.details ?? '').toLowerCase().contains(query)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [TextButton(onPressed: _clearFilters, child: const Text('Limpar filtros'))],
      ),
      body: StreamBuilder<_FilterData>(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          final accountNames = {for (final a in data?.accounts ?? <Account>[]) a.id: a.name};
          final tagNames = {for (final t in data?.tags ?? <Tag>[]) t.id: t.name};
          final filtered = (data?.transactions ?? []).where(_matches).toList();
          final total = BalanceCalculator.sumSigned(filtered);

          return ResponsiveBody(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: _buildFilters(data)),
                ),
                if (data == null)
                  const SliverFillRemaining(child: LoadingView())
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${filtered.length} lançamento(s)',
                                style: context.text.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AmountText(total, signed: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'Nenhum lançamento encontrado.',
                        message: 'Ajuste os filtros ou o período.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
                        itemBuilder: (context, i) {
                          final tx = filtered[i];
                          return TransactionTile(
                            transaction: tx,
                            accountName: _accountId == null ? accountNames[tx.accountId] : null,
                            tagName: tagNames[tx.tagId],
                            onTap: () => showTransactionForm(context, transaction: tx),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(_FilterData? data) {
    final accounts = data?.accounts ?? [];
    final tags = data?.tags ?? [];
    final validAccount = accounts.any((a) => a.id == _accountId) ? _accountId : null;
    final validTag = tags.any((t) => t.id == _tagId) ? _tagId : null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Buscar na descrição',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DateField(
                  label: 'De',
                  value: _fromDate,
                  emptyText: 'Início',
                  onChanged: (d) => _setPeriod(from: d),
                  onCleared: () => _setPeriod(clearFrom: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DateField(
                  label: 'Até',
                  value: _toDate,
                  emptyText: 'Hoje em diante',
                  onChanged: (d) => _setPeriod(to: d),
                  onCleared: () => _setPeriod(clearTo: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  value: validAccount,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Conta'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  value: validTag,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final t in tags) DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _tagId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<TransactionType?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Todos')),
              ButtonSegment(value: TransactionType.debit, label: Text('Despesas')),
              ButtonSegment(value: TransactionType.credit, label: Text('Receitas')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
        ],
      ),
    );
  }
}
