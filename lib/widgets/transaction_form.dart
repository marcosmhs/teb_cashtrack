import 'package:flutter/material.dart';

import '../controllers/account_controller.dart';
import '../controllers/tag_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../models/tag.dart';
import '../models/transaction.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';
import 'dialogs.dart';

/// Abre o formulário de lançamento em uma folha inferior.
/// Sem [transaction] cria um novo lançamento; com ele, edita (e permite excluir).
Future<void> showTransactionForm(BuildContext context, {Transaction? transaction}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => TransactionForm(transaction: transaction),
  );
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, this.transaction});

  final Transaction? transaction;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _txController = TransactionController();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();

  late final Stream<List<Account>> _accounts = AccountController().getAccounts();
  late final Stream<List<Tag>> _tags = TagController().getTags();

  late DateTime _date;
  late TransactionType _type;
  String? _accountId;
  String? _tagId;
  bool _saving = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _date = t?.date ?? DateTime.now();
    _type = t?.type ?? TransactionType.debit;
    _accountId = t?.accountId;
    _tagId = t?.tagId;
    if (t != null) {
      _amountController.text = centsToInputText(t.amountCents);
      _detailsController.text = t.details ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final details = _detailsController.text.trim();
    final transaction = Transaction(
      id: widget.transaction?.id ?? _txController.newId(),
      date: _date,
      accountId: _accountId!,
      amountCents: parseCurrencyToCents(_amountController.text),
      details: details.isEmpty ? null : details,
      tagId: _tagId,
      type: _type,
    );
    try {
      await _txController.saveTransaction(transaction);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, _isEditing ? 'Lançamento atualizado.' : 'Lançamento salvo.');
    } catch (e) {
      debugPrint('Erro ao salvar lançamento: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Não foi possível salvar o lançamento.');
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: 'Excluir lançamento?',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      await _txController.deleteTransaction(widget.transaction!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, 'Lançamento excluído.');
    } catch (e) {
      debugPrint('Erro ao excluir lançamento: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Não foi possível excluir o lançamento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    // Cabeçalho e campos rolam no meio; as tags e o botão de salvar ficam
    // fixos no rodapé (acima do teclado), sempre visíveis — evita rolar ou
    // fechar o teclado no celular para confirmar o lançamento.
    final maxHeight = media.size.height * 0.92 - bottomInset;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight > 0 ? maxHeight : media.size.height * 0.92,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar lançamento' : 'Novo lançamento',
                        style: context.text.titleLarge,
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        onPressed: _saving ? null : _delete,
                        icon: Icon(Icons.delete_outline, color: context.colors.error),
                        tooltip: 'Excluir lançamento',
                      ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<TransactionType>(
                        segments: [
                          ButtonSegment(
                            value: TransactionType.debit,
                            label: const Text('Despesa'),
                            icon: Icon(Icons.arrow_downward, color: context.finance.expense),
                          ),
                          ButtonSegment(
                            value: TransactionType.credit,
                            label: const Text('Receita'),
                            icon: Icon(Icons.arrow_upward, color: context.finance.income),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (s) => setState(() => _type = s.first),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _amountController,
                        autofocus: !_isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [CurrencyInputFormatter()],
                        style: context.text.headlineMedium,
                        decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
                        validator: (v) =>
                            parseCurrencyToCents(v ?? '') <= 0 ? 'Informe um valor' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildAccountField(),
                      const SizedBox(height: AppSpacing.md),
                      DateField(
                        label: 'Data',
                        value: _date,
                        onChanged: (d) => setState(() => _date = d),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _detailsController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTagSelector(),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Salvar alterações' : 'Salvar lançamento'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountField() {
    return StreamBuilder<List<Account>>(
      stream: _accounts,
      builder: (context, snapshot) {
        final accounts = (snapshot.data ?? [])
            .where((a) => a.active || a.id == widget.transaction?.accountId)
            .toList();
        final validId = accounts.any((a) => a.id == _accountId) ? _accountId : null;
        if (validId == null && accounts.isNotEmpty) {
          // Pré-seleciona o meio de pagamento principal; sem ele, a primeira
          // conta corrente ou, por fim, a primeira conta disponível.
          final preferred = accounts.firstWhere(
            (a) => a.isDefault,
            orElse: () => accounts.firstWhere(
              (a) => a.type == AccountType.checking,
              orElse: () => accounts.first,
            ),
          );
          _accountId = preferred.id;
        }
        return DropdownButtonFormField<String>(
          key: ValueKey(_accountId),
          value: _accountId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Meio de pagamento',
            helperText: snapshot.hasData && accounts.isEmpty
                ? 'Cadastre uma conta na aba Contas.'
                : null,
          ),
          items: [
            for (final a in accounts)
              DropdownMenuItem(
                value: a.id,
                child: Row(
                  children: [
                    Icon(a.type.icon, size: 20, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('${a.name} · ${a.type.label}', overflow: TextOverflow.ellipsis),
                    ),
                    if (a.isDefault) Icon(Icons.star, size: 18, color: context.colors.primary),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _accountId = v),
          validator: (v) => v == null ? 'Selecione o meio de pagamento' : null,
        );
      },
    );
  }

  Widget _buildTagSelector() {
    return StreamBuilder<List<Tag>>(
      stream: _tags,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? [];
        if (tags.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tag', style: context.text.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            // Altura limitada com rolagem própria: muitas tags não empurram
            // o botão de salvar para fora da tela.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 132),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: const Text('Sem tag'),
                      selected: _tagId == null,
                      onSelected: (_) => setState(() => _tagId = null),
                    ),
                    for (final tag in tags)
                      ChoiceChip(
                        label: Text(tag.name),
                        selected: _tagId == tag.id,
                        onSelected: (selected) =>
                            setState(() => _tagId = selected ? tag.id : null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
