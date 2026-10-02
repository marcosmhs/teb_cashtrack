import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:teb_cashtrack/controllers/auth_controller.dart';
import 'package:teb_cashtrack/firebase_options.dart';
import 'package:teb_cashtrack/theme.dart';
import 'package:teb_cashtrack/views/app_shell.dart';
import 'package:teb_cashtrack/views/login_view.dart';
import 'package:teb_cashtrack/widgets/common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Cashtrack());
}

class Cashtrack extends StatelessWidget {
  const Cashtrack({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEB CashTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthGate(),
    );
  }
}

/// Exibe o login ou o app conforme o estado de autenticação do Firebase.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authState = AuthController().authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final user = snapshot.data;
        // A chave por usuário recria o app (e seus streams) ao trocar de conta.
        return user == null ? const LoginView() : AppShell(key: ValueKey(user.uid));
      },
    );
  }
}
