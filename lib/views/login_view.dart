import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _authController.tryAutoLogin();
      if (user != null && mounted) {
        _goToHome();
        return;
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _goToHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
  }

  Future<void> _authenticate({required bool createAccount}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Informe e-mail e senha.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (createAccount) {
        await _authController.signUp(email, password);
      } else {
        await _authController.signIn(email, password);
      }
      _goToHome();
    } catch (error) {
      setState(() {
        _loading = false;
        _errorMessage = error is Exception ? error.toString() : 'Erro ao autenticar.';
      });
    }
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),
                Text(
                  'CashTrack',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'Acesse sua conta para acompanhar lançamentos e cartões.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(height: 36),
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
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 18),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _loading ? null : () => _authenticate(createAccount: false),
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : () => _authenticate(createAccount: true),
                  child: const Text('Criar conta'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Os dados de login são armazenados localmente para reinício automático na próxima abertura do app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
