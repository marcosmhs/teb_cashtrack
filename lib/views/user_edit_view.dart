import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../services/legacy_migration_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class UserEditView extends StatefulWidget {
  const UserEditView({super.key});

  @override
  State<UserEditView> createState() => _UserEditViewState();
}

class _UserEditViewState extends State<UserEditView> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();
  late final _emailController = TextEditingController(text: _authController.currentEmail ?? '');
  final _passwordController = TextEditingController();
  bool _saving = false;
  bool _migrating = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailChanged = email != (_authController.currentEmail ?? '');

    if (!emailChanged && password.isEmpty) {
      showMessage(context, 'Nenhuma alteração para salvar.');
      return;
    }

    setState(() => _saving = true);
    final messages = <String>[];
    try {
      if (emailChanged) {
        await _authController.updateEmail(email);
        messages.add('Enviamos um link de confirmação para $email.');
      }
      if (password.isNotEmpty) {
        await _authController.updatePassword(password);
        _passwordController.clear();
        messages.add('Senha alterada.');
      }
      if (mounted) showMessage(context, messages.join(' '));
    } catch (error) {
      if (mounted) showMessage(context, AuthController.describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    // O AuthGate exibe o login automaticamente quando a sessão termina.
    Navigator.of(context).popUntil((route) => route.isFirst);
    await _authController.signOut();
  }

  Future<void> _importLegacyData() async {
    final confirmed = await confirmAction(
      context,
      title: 'Importar dados antigos?',
      message:
          'Os dados gravados pela versão anterior do app serão copiados para a sua conta. '
          'Itens já importados são sobrescritos, sem duplicar.',
      confirmLabel: 'Importar',
    );
    if (!confirmed) return;
    setState(() => _migrating = true);
    try {
      final result = await LegacyMigrationService().migrate();
      final total = result.values.fold(0, (a, b) => a + b);
      if (mounted) showMessage(context, '$total registro(s) importado(s).');
    } catch (e) {
      debugPrint('Erro na importação: $e');
      if (mounted) {
        showMessage(context, 'Não foi possível importar. Verifique as regras do Firestore.');
      }
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _migrating;
    return Scaffold(
      appBar: AppBar(title: const Text('Dados do usuário')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveBody(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (v) =>
                            (v ?? '').contains('@') ? null : 'Informe um e-mail válido',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nova senha',
                          helperText: 'Deixe em branco para manter a senha atual.',
                        ),
                        validator: (v) =>
                            (v ?? '').isNotEmpty && v!.length < 6 ? 'Mínimo de 6 caracteres' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: busy ? null : _saveChanges,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Salvar alterações'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Dados da versão anterior', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Se você usava o app antes da separação de dados por usuário, '
                      'importe seus registros antigos para esta conta.',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _importLegacyData,
                      icon: _migrating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: const Text('Importar dados antigos'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: busy ? null : _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.error,
                  side: BorderSide(color: context.colors.error),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
