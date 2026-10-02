import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

/// Tela de login/cadastro. Após autenticar, o [AuthGate] troca para o app automaticamente.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate({required bool createAccount}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      if (createAccount) {
        await _authController.signUp(email, password);
      } else {
        await _authController.signIn(email, password);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = AuthController.describeError(error);
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Informe seu e-mail para redefinir a senha.');
      return;
    }
    try {
      await _authController.sendPasswordReset(email);
      if (mounted) showMessage(context, 'Enviamos um link de redefinição para $email.');
    } catch (error) {
      if (mounted) setState(() => _errorMessage = AuthController.describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ResponsiveBody(
            maxWidth: 420,
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 56, color: context.colors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'CashTrack',
                      textAlign: TextAlign.center,
                      style: context.text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Acompanhe contas, cartões e lançamentos.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => (v ?? '').contains('@') ? null : 'Informe um e-mail válido',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _authenticate(createAccount: false),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v ?? '').isEmpty ? 'Informe a senha' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: context.text.bodyMedium?.copyWith(color: context.colors.error),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    FilledButton(
                      onPressed: _loading ? null : () => _authenticate(createAccount: false),
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _authenticate(createAccount: true),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
