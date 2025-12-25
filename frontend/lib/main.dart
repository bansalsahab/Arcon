import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'screens/auth/login_screen.dart';
import 'screens/app_shell.dart';
import 'theme/banking_theme.dart';
import 'utils/notifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roundup App',
      theme: bankingTheme(),
      home: const _AuthGate(),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Notifier.messengerKey,
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({Key? key}) : super(key: key);
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await ApiClient.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _loggedIn = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? const AppShell() : const LoginScreen();
  }
}
