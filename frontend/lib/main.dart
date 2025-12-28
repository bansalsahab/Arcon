import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:roundup_app/screens/auth/otp_login_screen.dart';
import 'package:roundup_app/screens/app_shell.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('Could not load .env file, using defaults');
  }
  
  runApp(const RoundupApp());
}

class RoundupApp extends StatelessWidget {
  const RoundupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roundup Investment App',
      theme: finPadiTheme(),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      scaffoldMessengerKey: Notifier.messengerKey,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      await ApiClient.me();
      if (mounted) setState(() => _isAuthenticated = true);
    } catch (_) {
      if (mounted) setState(() => _isAuthenticated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return Scaffold(
        backgroundColor: FinPadi_Background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: FinPadi_NavyBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FinPadi_NavyBlue),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated!) {
      return const AppShell();
    }

    return const OTPLoginScreen();
  }
}
