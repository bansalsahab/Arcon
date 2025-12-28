import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import '../app_shell.dart';
import 'register_screen.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'otp_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.login(_emailCtl.text.trim(), _passwordCtl.text);
      Notifier.success('Logged in');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v==null||v.isEmpty) ? 'Required' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v==null||v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Login'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: _loading ? null : (){
                      Navigator.of(context).push(MaterialPageRoute(builder: (_)=> const RegisterScreen()));
                    },
                    child: const Text('Register'),
                  )
                ],
              )
              ,
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (_)=> const OTPLoginScreen()));
                  },
                  child: const Text('Login with phone OTP'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
