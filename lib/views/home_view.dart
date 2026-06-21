import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teb_cashtrack/views/user_edit_view.dart';
import 'account_list_view.dart';
import '../controllers/account_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/transaction.dart' as tx_model;
import 'transaction_statement_view.dart';
import 'transaction_filter_view.dart';
import 'tag_list_view.dart';
import 'transaction_edit_view.dart';
import 'shopping_list_view.dart';
import '../models/tag.dart';
import '../controllers/tag_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  final AccountController _accountController = AccountController();
  final TransactionController _transactionController = TransactionController();
  final TagController _tagController = TagController();

  final TextEditingController _quickAmountController = TextEditingController();
  final TextEditingController _quickDetailsController = TextEditingController();
  DateTime _quickDate = DateTime.now();
  String? _selectedAccountId;
  String _quickType = 'debit';
  Tag? _selectedTag;
  bool _isQuickFormatting = false;

  @override
  void initState() {
    super.initState();
    _quickAmountController.addListener(_formatQuickAmount);
  }

  @override
  void dispose() {
    _quickAmountController.removeListener(_formatQuickAmount);
    _quickAmountController.dispose();
    _quickDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'CashTrack',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.person, color: Theme.of(context).colorScheme.primaryContainer),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserEditView())),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuickActionSection(),
            const SizedBox(height: 24),
            _buildBalanceAndCardsGrid(),
            const SizedBox(height: 24),
            _buildRecentTransactionsSection(),
            const SizedBox(height: 96),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildQuickActionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Theme.of(context).colorScheme.primaryContainer),
              const SizedBox(width: 8),
              Text(
                'Lançamento Rápido',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _quickAmountController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<Account>>(
                  stream: _accountController.getAccounts(),
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? [];
                    final items = accounts
                        .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList();
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedAccountId ?? (items.isNotEmpty ? items.first.value : null),
                      items: items,
                      decoration: InputDecoration(
                        labelText: 'Conta',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final tag = await Navigator.of(context).push<Tag?>(
                      MaterialPageRoute(builder: (_) => const TagListView(forSelection: true)),
                    );
                    if (tag != null) setState(() => _selectedTag = tag);
                  },
                  child: Text(_selectedTag?.name ?? 'Selecionar tag'),
                ),
              ),
              if (_selectedTag != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedTag = null),
                  tooltip: 'Limpar tag',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quickDetailsController,
            decoration: InputDecoration(
              labelText: 'Descrição (opcional)',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _quickDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _quickDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('${_quickDate.toLocal()}'.split(' ')[0]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _quickType,
                  items: const [
                    DropdownMenuItem(value: 'debit', child: Text('Débito')),
                    DropdownMenuItem(value: 'credit', child: Text('Crédito')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _quickType = v ?? 'debit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _performQuickTransaction,
              child: const Text('Confirmar Lançamento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceAndCardsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildBalanceCard()),
              const SizedBox(width: 24),
              Expanded(flex: 7, child: _buildCardGrid()),
            ],
          );
        }
        return Column(
          children: [_buildBalanceCard(), const SizedBox(height: 16), _buildCardGrid()],
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Disponível',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Account>>(
                    stream: _accountController.getAccounts(),
                    builder: (context, snapshot) {
                      final accounts = snapshot.data ?? [];
                      final correnteIds = accounts
                          .where((a) => a.type == 'Conta Corrente')
                          .map((a) => a.id)
                          .toList();
                      return StreamBuilder<double>(
                        stream: _transactionController.getTotalForAccountIds(correnteIds),
                        builder: (context, s2) {
                          final total = s2.data ?? 0.0;
                          return Text(
                            'R\$ ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Color(0xFFE6F7EE),
                child: Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Contas Correntes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Account>>(
            stream: _accountController.getAccounts(),
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? [];
              final correnteAccounts = accounts.where((a) => a.type == 'Conta Corrente').toList();
              if (correnteAccounts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Nenhuma conta corrente cadastrada.'),
                );
              }
              return Column(
                children: correnteAccounts.map((account) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Conta corrente',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          StreamBuilder<double>(
                            stream: _transactionController.getTotalForAccountIds([account.id]),
                            builder: (context, s) {
                              final balance = s.data ?? 0.0;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'R\$ ${balance.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 120,
                                    child: FilledButton(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransactionStatementView(
                                            accountIds: [account.id],
                                            accountName: account.name,
                                          ),
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                      child: const Text('Ver extrato'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    return StreamBuilder<List<Account>>(
      stream: _accountController.getAccounts(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        final cards = accounts.where((a) => a.type == 'Cartão de Crédito').toList();
        if (cards.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(child: Text('Nenhum cartão de crédito cadastrado.')),
          );
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Cartões de Crédito',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text('Total das faturas', style: TextStyle(color: Color(0xFF94A3B8))),
                    ],
                  ),
                  StreamBuilder<double>(
                    stream: _transactionController.getTotalForAccountIds(
                      cards.map((a) => a.id).toList(),
                    ),
                    builder: (context, s) {
                      final total = (s.data ?? 0.0).abs();
                      return Text(
                        'R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: cards.map((account) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Fatura atual',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          StreamBuilder<List<tx_model.Transaction>>(
                            stream: _transactionController.getTransactionsForAccount(account.id),
                            builder: (context, s) {
                              final txs = s.data ?? [];
                              double total = 0;
                              for (final t in txs) {
                                if (t.type == 'debit') {
                                  total += t.amount;
                                } else {
                                  total -= t.amount;
                                }
                              }
                              total = total.abs();
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'R\$ ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 100,
                                    child: FilledButton(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransactionStatementView(
                                            accountIds: [account.id],
                                            accountName: account.name,
                                          ),
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                      child: const Text('Extrato'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimos Lançamentos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const TransactionFilterView())),
                  icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF10B981)),
                  label: const Text(
                    'Ver todos',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          StreamBuilder<List<tx_model.Transaction>>(
            stream: _transactionController.getLatestTransactions(20),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final txs = snapshot.data ?? [];
              if (txs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhum lançamento encontrado.')),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: txs.take(5).map((t) => _buildTransactionTile(t)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(tx_model.Transaction t) {
    final isDebit = t.type == 'debit';
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => TransactionEditView(transaction: t))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDebit ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDebit ? Icons.remove : Icons.add,
                          color: isDebit ? const Color(0xFFB91C1C) : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.details ?? (isDebit ? 'Débito' : 'Crédito'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t.date.toLocal()}'.split(' ')[0],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            if (t.tagId != null && t.tagId!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              FutureBuilder<Tag?>(
                                future: _tagController.getTagById(t.tagId!),
                                builder: (context, snap) {
                                  if (!snap.hasData || snap.data == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final tag = snap.data as Tag;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${isDebit ? '-' : '+'} R\$ ${t.amount.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDebit ? const Color(0xFFB91C1C) : const Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 0),
      ],
    );
  }

  void _formatQuickAmount() {
    if (_isQuickFormatting) return;
    _isQuickFormatting = true;
    final digits = _quickAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _quickAmountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isQuickFormatting = false;
      return;
    }

    final normalizedDigits = digits.replaceFirst(RegExp(r'^0+(?!$)'), '');
    final cents = normalizedDigits.length > 1
        ? normalizedDigits.substring(normalizedDigits.length - 2)
        : normalizedDigits.padLeft(2, '0');
    final reais = normalizedDigits.length > 2
        ? normalizedDigits.substring(0, normalizedDigits.length - 2)
        : '0';
    final formatted = '$reais,$cents';
    _quickAmountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isQuickFormatting = false;
  }

  double _parseCurrency(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0.0;
    return int.parse(digits) / 100;
  }

  Future<void> _performQuickTransaction() async {
    String? accountId = _selectedAccountId;
    // If no account explicitly selected, pick the first available account from stream
    if (accountId == null) {
      try {
        final accounts = await _accountController.getAccounts().first;
        if (accounts.isNotEmpty) accountId = accounts.first.id;
      } catch (e) {
        // fallback remains null
        debugPrint('Erro ao obter contas para seleção padrão: $e');
      }
    }
    final amount = _parseCurrency(_quickAmountController.text);
    String? tagId = _selectedTag?.id;
    if (accountId == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe conta e um valor válido.')));
      return;
    }

    final tx = tx_model.Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _quickDate,
      accountId: accountId,
      amount: amount,
      details: _quickDetailsController.text.trim().isEmpty
          ? null
          : _quickDetailsController.text.trim(),
      tagId: tagId,
      type: _quickType,
    );

    try {
      await _transactionController.addTransaction(tx);
      _quickAmountController.clear();
      _quickDetailsController.clear();
      _quickDate = DateTime.now();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lançamento salvo.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Widget _buildBottomNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = index == _selectedIndex;
    final color = isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: () {
        if (index == 1) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountListView()));
          return;
        }
        if (index == 2) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TagListView()));
          return;
        }
        if (index == 3) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShoppingListView()));
          return;
        }
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(70), blurRadius: 16)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(icon: Icons.home, label: 'Início', index: 0),
          _buildBottomNavItem(icon: Icons.account_balance, label: 'Contas', index: 1),
          _buildBottomNavItem(icon: Icons.label, label: 'Tags', index: 2),
          _buildBottomNavItem(icon: Icons.shopping_bag, label: 'Compras', index: 3),
        ],
      ),
    );
  }
}
