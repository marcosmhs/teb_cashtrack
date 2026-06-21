import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // Certifique-se de ter 'rxdart' no pubspec.yaml
import '../controllers/account_controller.dart';
import '../controllers/tag_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/tag.dart';
import '../models/transaction.dart';
import 'transaction_edit_view.dart';

class FilterScreenData {
  final List<Account> accounts;
  final List<Tag> tags;
  final List<Transaction> transactions;

  FilterScreenData({required this.accounts, required this.tags, required this.transactions});
}

class TransactionFilterView extends StatefulWidget {
  const TransactionFilterView({super.key});

  @override
  State<TransactionFilterView> createState() => _TransactionFilterViewState();
}

class _TransactionFilterViewState extends State<TransactionFilterView> {
  final TransactionController _txController = TransactionController();
  final AccountController _accountController = AccountController();
  final TagController _tagController = TagController();

  late final Stream<FilterScreenData> _combinedStream;

  String? _selectedAccountId;
  String _selectedType = 'all';
  String? _selectedTagId;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _combinedStream =
        Rx.combineLatest3<List<Account>, List<Tag>, List<Transaction>, FilterScreenData>(
          _accountController.getAccounts(),
          _tagController.getTags(),
          _txController.getTransactions(),
          (accounts, tags, transactions) =>
              FilterScreenData(accounts: accounts, tags: tags, transactions: transactions),
        ).asBroadcastStream();
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _matchesFilters(Transaction tx) {
    final txDate = _dateOnly(tx.date);
    if (_selectedAccountId != null && tx.accountId != _selectedAccountId) return false;
    if (_selectedType != 'all' && tx.type != _selectedType) return false;
    if (_selectedTagId != null && tx.tagId != _selectedTagId) return false;
    if (_fromDate != null && txDate.isBefore(_dateOnly(_fromDate!))) return false;
    if (_toDate != null && txDate.isAfter(_dateOnly(_toDate!))) return false;
    return true;
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initialDate = isFrom ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedAccountId = null;
      _selectedType = 'all';
      _selectedTagId = null;
      _fromDate = null;
      _toDate = null;
      _showResults = false;
    });
  }

  void _searchTransactions() {
    setState(() {
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos filtrados'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF10B981)),
        elevation: 0,
      ),
      body: StreamBuilder<FilterScreenData>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os dados.'));
          }

          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();

          final accounts = data.accounts;
          final tags = data.tags;
          final transactions = data.transactions;

          final accountMap = {for (final account in accounts) account.id: account.name};
          final tagMap = {for (final tag in tags) tag.id: tag.name};

          final filtered = transactions.where(_matchesFilters).toList();
          final total = filtered.fold<double>(0.0, (sum, tx) {
            return sum + (tx.type == 'debit' ? -tx.amount : tx.amount);
          });

          final totalText = total < 0
              ? '- R\$ ${total.abs().toStringAsFixed(2)}'
              : 'R\$ ${total.toStringAsFixed(2)}';
          final totalColor = total < 0 ? const Color(0xFFB91C1C) : const Color(0xFF10B981);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Filtros',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),

                      // Primeira Linha: Conta e Tipo
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedAccountId,
                              decoration: InputDecoration(
                                labelText: 'Conta',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Todas')),
                                ...accounts.map(
                                  (account) => DropdownMenuItem(
                                    value: account.id,
                                    child: Text(account.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(() => _selectedAccountId = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Todos')),
                                DropdownMenuItem(value: 'debit', child: Text('Débito')),
                                DropdownMenuItem(value: 'credit', child: Text('Crédito')),
                              ],
                              onChanged: (value) => setState(() => _selectedType = value ?? 'all'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Segunda Linha: Tag e De
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedTagId,
                              decoration: InputDecoration(
                                labelText: 'Tag',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Todas')),
                                ...tags.map(
                                  (tag) => DropdownMenuItem(value: tag.id, child: Text(tag.name)),
                                ),
                              ],
                              onChanged: (value) => setState(() => _selectedTagId = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'De',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _fromDate != null
                                      ? '${_dateOnly(_fromDate!).toLocal()}'.split(' ')[0]
                                      : 'Qualquer data',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Terceira Linha Corrigida: Até, Limpar e Buscar dividindo o espaço igualmente
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Até',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _toDate != null
                                      ? '${_dateOnly(_toDate!).toLocal()}'.split(' ')[0]
                                      : 'Qualquer data',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _clearFilters,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Limpar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _searchTransactions,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Buscar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_showResults)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        'Use os filtros e toque em Buscar para ver os lançamentos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total exibido',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          totalText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: totalColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text('Nenhum lançamento encontrado para os filtros selecionados.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isDebit = tx.type == 'debit';
                        return InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TransactionEditView(transaction: tx)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isDebit
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFDCFCE7),
                                  child: Icon(
                                    isDebit ? Icons.remove : Icons.add,
                                    color: isDebit
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.details ?? (isDebit ? 'Débito' : 'Crédito'),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${'${_dateOnly(tx.date).toLocal()}'.split(' ')[0]} • ${tx.date.toLocal().toIso8601String().split('T').last.substring(0, 5)}',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (_selectedAccountId == null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          accountMap[tx.accountId] ?? 'Conta',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      if (tx.tagId != null && tx.tagId!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            tagMap[tx.tagId!] ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${isDebit ? '-' : '+'} R\$ ${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDebit
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
