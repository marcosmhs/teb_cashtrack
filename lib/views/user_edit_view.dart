import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';

class UserEditView extends StatefulWidget {
  const UserEditView({super.key});

  @override
  State<UserEditView> createState() => _UserEditViewState();
}

class _UserEditViewState extends State<UserEditView> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _saving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    final email = await _authController.getCurrentEmail();
    if (mounted) {
      _emailController.text = email ?? '';
    }
  }

  Future<void> _saveChanges() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      setState(() => _statusMessage = 'Informe um e-mail válido.');
      return;
    }

    setState(() {
      _saving = true;
      _statusMessage = null;
    });

    try {
      await _authController.updateEmail(email);
      if (password.isNotEmpty) {
        await _authController.updatePassword(password);
      }
      setState(() => _statusMessage = 'Dados atualizados com sucesso.');
    } catch (error) {
      setState(
        () => _statusMessage = error is Exception ? error.toString() : 'Erro ao atualizar dados.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await _authController.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginView()), (_) => false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados do Usuário'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  helperText: 'Deixe em branco para manter a senha atual',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_statusMessage != null) ...[
                Text(_statusMessage!, style: const TextStyle(color: Color(0xFF10B981))),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _saving ? null : _saveChanges,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar alterações'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _saving ? null : _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                ),
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
