import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:teb_cashtrack/firebase_options.dart';
import 'package:teb_cashtrack/theme.dart';
import 'package:teb_cashtrack/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: AppTheme.themeData,
      home: const HomeView(),
    );
  }
}
