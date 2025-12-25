import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:bankingapp/banking/screen/BankingDashboard.dart';
import 'package:bankingapp/banking/utils/BankingWidget.dart';
import 'package:bankingapp/banking/utils/BankingStrings.dart';
import 'package:bankingapp/services/api.dart';

class BankingRegister extends StatefulWidget {
  static var tag = "/BankingRegister";
  @override
  _BankingRegisterState createState() => _BankingRegisterState();
}

class _BankingRegisterState extends State<BankingRegister> {
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passwordCtl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('Create Account', style: boldTextStyle(size: 30)),
            8.height,
            EditText(text: 'Full Name', isPassword: false, mController: _nameCtl),
            8.height,
            EditText(text: 'Email', isPassword: false, mController: _emailCtl),
            8.height,
            EditText(text: 'Password', isPassword: true, isSecure: true, mController: _passwordCtl),
            16.height,
            BankingButton(
              textContent: Banking_lbl_Get_Started,
              onPressed: () async {
                if (_loading) return;
                setState(() { _loading = true; });
                try {
                  await ApiClient.register(_emailCtl.text.trim(), _passwordCtl.text, fullName: _nameCtl.text.trim());
                  BankingDashboard().launch(context, isNewTask: true);
                } catch (e) {
                  toast(e.toString());
                } finally {
                  if (mounted) setState(() { _loading = false; });
                }
              },
            ),
          ],
        ).center(),
      ),
    );
  }
}
