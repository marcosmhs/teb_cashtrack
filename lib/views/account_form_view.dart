import 'package:flutter/material.dart';

import '../controllers/account_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/account.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class AccountFormView extends StatefulWidget {
  const AccountFormView({super.key, this.account});

  final Account? account;

  @override
  State<AccountFormView> createState() => _AccountFormViewState();
}

class _AccountFormViewState extends State<AccountFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _closingDayController = TextEditingController();
  final _accountController = AccountController();

  AccountType _type = AccountType.checking;
  bool _negativeBalance = false;
  bool _active = true;
  bool _saving = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null) {
      _nameController.text = account.name;
      _balanceController.text = centsToInputText(account.initialBalanceCents.abs());
      _negativeBalance = account.initialBalanceCents < 0;
      _closingDayController.text = account.closingDay?.toString() ?? '';
      _type = account.type;
      _active = account.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _closingDayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final balance = parseCurrencyToCents(_balanceController.text);
    final account = Account(
      id: widget.account?.id ?? _accountController.newId(),
      name: _nameController.text.trim(),
      type: _type,
      initialBalanceCents: _negativeBalance ? -balance : balance,
      active: _active,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
      closingDay: int.tryParse(_closingDayController.text),
    );

    try {
      await _accountController.saveAccount(account);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, _isEditing ? 'Conta atualizada.' : 'Conta cadastrada.');
    } catch (e) {
      debugPrint('Erro ao salvar conta: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Não foi possível salvar a conta.');
    }
  }

  Future<void> _delete() async {
    final account = widget.account!;
    // Impede excluir contas com lançamentos, para não deixar lançamentos órfãos.
    final count = await TransactionController().countForAccount(account.id);
    if (!mounted) return;
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Conta com lançamentos'),
          content: Text(
            '"${account.name}" possui $count lançamento(s) e não pode ser excluída. '
            'Você pode marcá-la como inativa para ocultá-la da tela inicial.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await confirmAction(
      context,
      title: 'Excluir conta?',
      message: 'Excluir "${account.name}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) return;
    await _accountController.deleteAccount(account.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, 'Conta excluída.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar conta' : 'Nova conta'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline, color: context.colors.error),
              tooltip: 'Excluir conta',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveBody(
          maxWidth: 560,
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex.: Banco do Brasil, Nubank',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<AccountType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final t in AccountType.values)
                        DropdownMenuItem(value: t, child: Text(t.label)),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_type == AccountType.creditCard)
                    TextFormField(
                      controller: _closingDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dia de fechamento da fatura',
                        helperText: 'Usado para calcular a fatura atual (1 a 31).',
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return null;
                        final day = int.tryParse(v!);
                        return day == null || day < 1 || day > 31
                            ? 'Informe um dia entre 1 e 31'
                            : null;
                      },
                    )
                  else ...[
                    TextFormField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Saldo inicial',
                        prefixText: r'R$ ',
                        hintText: '0,00',
                        helperText: 'Saldo da conta antes do primeiro lançamento no app.',
                      ),
                    ),
                    CheckboxListTile(
                      value: _negativeBalance,
                      onChanged: (v) => setState(() => _negativeBalance = v ?? false),
                      title: const Text('Saldo inicial negativo'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text('Conta ativa'),
                    subtitle: const Text('Contas inativas não aparecem na tela inicial.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Salvar alterações' : 'Cadastrar conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
