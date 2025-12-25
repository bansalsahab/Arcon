import 'package:bankingapp/banking/screen/BankingDashboard.dart';
import 'package:bankingapp/banking/screen/BankingForgotPassword.dart';
import 'package:bankingapp/banking/screen/BankingRegister.dart';
import 'package:bankingapp/services/api.dart';
import 'package:bankingapp/banking/utils/BankingColors.dart';
import 'package:bankingapp/banking/utils/BankingImages.dart';
import 'package:bankingapp/banking/utils/BankingStrings.dart';
import 'package:bankingapp/banking/utils/BankingWidget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class BankingSignIn extends StatefulWidget {
  static var tag = "/BankingSignIn";

  @override
  _BankingSignInState createState() => _BankingSignInState();
}

class _BankingSignInState extends State<BankingSignIn> {
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passwordCtl = TextEditingController();
  bool _loading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(Banking_lbl_SignIn, style: boldTextStyle(size: 30)),
                EditText(text: "Email", isPassword: false, mController: _emailCtl),
                8.height,
                EditText(text: "Password", isPassword: true, isSecure: true, mController: _passwordCtl),
                8.height,
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(Banking_lbl_Forgot, style: secondaryTextStyle(size: 16)).onTap(
                    () {
                      BankingForgotPassword().launch(context);
                    },
                  ),
                ),
                16.height,
                BankingButton(
                  textContent: Banking_lbl_SignIn,
                  onPressed: () async {
                    if (_loading) return;
                    setState(() { _loading = true; });
                    try {
                      await ApiClient.login(_emailCtl.text.trim(), _passwordCtl.text);
                      BankingDashboard().launch(context, isNewTask: true);
                    } catch (e) {
                      toast(e.toString());
                    } finally {
                      if (mounted) setState(() { _loading = false; });
                    }
                  },
                ),
                16.height,
                Column(
                  children: [
                    Text(Banking_lbl_Login_with_FaceID, style: primaryTextStyle(size: 16, color: Banking_TextColorSecondary)).onTap(() {}),
                    16.height,
                    Image.asset(Banking_ic_face_id, color: Banking_Primary, height: 40, width: 40),
                    24.height,
                    Text('Create Account', style: primaryTextStyle(size: 16, color: Banking_Primary)).onTap(() {
                      BankingRegister().launch(context);
                    }),
                  ],
                ).center(),
              ],
            ).center(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(Banking_lbl_app_Name.toUpperCase(), style: primaryTextStyle(size: 16, color: Banking_TextColorSecondary)),
          ).paddingBottom(16),
        ],
      ),
    );
  }
}
