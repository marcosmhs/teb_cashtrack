import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/account_controller.dart';
import '../controllers/tag_controller.dart';
import '../models/transaction.dart' as tx_model;
import '../models/account.dart';
import 'tag_list_view.dart';
import '../models/tag.dart';

class TransactionEditView extends StatefulWidget {
  final tx_model.Transaction transaction;
  const TransactionEditView({super.key, required this.transaction});

  @override
  State<TransactionEditView> createState() => _TransactionEditViewState();
}

class _TransactionEditViewState extends State<TransactionEditView> {
  final TransactionController _txController = TransactionController();
  final AccountController _accountController = AccountController();
  final TagController _tagController = TagController();

  late TextEditingController _amountController;
  late TextEditingController _detailsController;
  late DateTime _date;
  String? _selectedAccountId;
  String _type = 'debit';
  Tag? _selectedTag;
  bool _isAmountFormatting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountController = TextEditingController(text: t.amount.toStringAsFixed(2));
    _amountController.addListener(_formatAmountInput);
    _detailsController = TextEditingController(text: t.details ?? '');
    _date = t.date;
    _selectedAccountId = t.accountId;
    _type = t.type;
    if (t.tagId != null && t.tagId!.isNotEmpty) {
      _selectedTag = Tag(id: t.tagId!, name: ''); // placeholder until resolved
      // resolve full tag name
      _resolveTagName(t.tagId!);
    }
  }

  Future<void> _resolveTagName(String id) async {
    try {
      final tag = await _tagController.getTagById(id);
      if (tag != null && mounted) setState(() => _selectedTag = tag);
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmountInput);
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickTag() async {
    final tag = await Navigator.of(
      context,
    ).push<Tag?>(MaterialPageRoute(builder: (_) => const TagListView(forSelection: true)));
    if (tag != null) setState(() => _selectedTag = tag);
  }

  Future<void> _save() async {
    final amount = _parseCurrency(_amountController.text);
    if (_selectedAccountId == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe conta e valor válido.')));
      return;
    }

    final updated = tx_model.Transaction(
      id: widget.transaction.id,
      date: _date,
      accountId: _selectedAccountId!,
      amount: amount,
      details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      tagId: _selectedTag?.id,
      type: _type,
    );

    await _txController.updateTransaction(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _formatAmountInput() {
    if (_isAmountFormatting) return;
    _isAmountFormatting = true;
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isAmountFormatting = false;
      return;
    }
    final cents = digits.length > 1 ? digits.substring(digits.length - 2) : digits.padLeft(2, '0');
    final reais = digits.length > 2 ? digits.substring(0, digits.length - 2) : '0';
    final formatted = '$reais,$cents';
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isAmountFormatting = false;
  }

  double _parseCurrency(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0.0;
    return int.parse(digits) / 100;
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text('Deseja realmente excluir este lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _txController.deleteTransaction(widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Lançamento'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Account>>(
              stream: _accountController.getAccounts(),
              builder: (context, s) {
                final accounts = s.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId ?? (accounts.isNotEmpty ? accounts.first.id : null),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  decoration: const InputDecoration(labelText: 'Conta'),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'debit', child: Text('Débito')),
                      DropdownMenuItem(value: 'credit', child: Text('Crédito')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'debit'),
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _pickTag,
                    child: Text(_selectedTag?.name ?? 'Selecionar tag'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: _save, child: const Text('Salvar')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _delete,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    child: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
