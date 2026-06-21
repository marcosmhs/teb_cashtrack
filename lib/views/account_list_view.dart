import 'package:flutter/material.dart';
import '../controllers/account_controller.dart';
import '../models/account.dart';
import 'account_form_view.dart';

class AccountListView extends StatefulWidget {
  const AccountListView({super.key});

  @override
  State<AccountListView> createState() => _AccountListViewState();
}

class _AccountListViewState extends State<AccountListView> {
  final AccountController _accountController = AccountController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF10B981)),
        title: const Text('Contas Cadastradas', style: TextStyle(color: Color(0xFF111827))),
      ),
      body: StreamBuilder<List<Account>>(
        stream: _accountController.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final accounts = snapshot.data ?? [];
          if (accounts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildAccountTile(accounts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAccount,
        icon: const Icon(Icons.add),
        label: const Text('Nova Conta'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet, size: 72, color: Color(0xFF10B981)),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma conta cadastrada ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toque no botão abaixo para criar a primeira conta e começar a gerenciar seus ativos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _openCreateAccount,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Criar Conta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(Account account) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 18)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: account.active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
            child: Icon(
              account.active ? Icons.check_circle : Icons.remove_circle_outline,
              color: account.active ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(account.email, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(account.type, const Color(0xFFF0FDF4), const Color(0xFF15803D)),
                    _buildBadge(
                      account.active ? 'Ativa' : 'Inativa',
                      account.active ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                      account.active ? const Color(0xFF166534) : const Color(0xFF475569),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${account.balance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _openEditAccount(account),
                    icon: const Icon(Icons.edit, color: Color(0xFF10B981)),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(account),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _openCreateAccount() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountFormView()));
  }

  void _openEditAccount(Account account) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AccountFormView(account: account)));
  }

  Future<void> _confirmDelete(Account account) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir conta'),
          content: Text('Tem certeza que deseja excluir "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      await _accountController.deleteAccount(account.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conta excluída com sucesso.')));
    }
  }
}
