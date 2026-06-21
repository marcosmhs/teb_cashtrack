import 'package:flutter/material.dart';
import '../controllers/account_controller.dart';
import '../models/account.dart';

class AccountFormView extends StatefulWidget {
  final Account? account;

  const AccountFormView({super.key, this.account});

  @override
  State<AccountFormView> createState() => _AccountFormViewState();
}

class _AccountFormViewState extends State<AccountFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final AccountController _accountController = AccountController();

  String _selectedType = 'Conta Corrente';
  bool _active = true;
  final List<String> _accountTypes = ['Conta Corrente', 'Cartão de Crédito', 'Investimento'];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toStringAsFixed(2);
      _selectedType = widget.account!.type;
      _active = widget.account!.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF10B981)),
        title: Text(
          isEditing ? 'Editar Conta' : 'Criar Nova Conta',
          style: const TextStyle(color: Color(0xFF111827)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(75), blurRadius: 24)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Preencha os dados da conta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Nome da Conta',
                  controller: _nameController,
                  hintText: 'Ex: Carteira Principal',
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Saldo Inicial',
                  controller: _balanceController,
                  hintText: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: _buildInputDecoration(label: 'Tipo de Conta'),
                  items: _accountTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                      activeColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Text(_active ? 'Ativa' : 'Inativa', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saveAccount,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? 'Salvar Alterações' : 'Cadastrar Conta',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label: label).copyWith(hintText: hintText),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Preencha este campo';
        }
        return null;
      },
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final balance = double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
    final account = Account(
      id: widget.account?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: '',
      type: _selectedType,
      balance: balance,
      active: _active,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.account == null) {
        await _accountController.addAccount(account);
      } else {
        await _accountController.updateAccount(account);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.account == null
                ? 'Conta cadastrada com sucesso.'
                : 'Conta atualizada com sucesso.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar conta: $error')));
    }
  }
}
