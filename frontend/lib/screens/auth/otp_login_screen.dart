import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/notifier.dart';
import '../app_shell.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({super.key});

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  // 0 = Phone Input, 1 = OTP Verification
  int _step = 0;
  
  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _focusNode = FocusNode(); // For OTP hidden input
  
  bool _isLoading = false;
  String? _devCode; // For showing the code in dev mode

  @override
  void dispose() {
    _phoneCtl.dispose();
    _codeCtl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _requestOtp() async {
    final phone = _phoneCtl.text.trim();
    if (phone.length < 10) {
      Notifier.error('Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.requestOtp(phone);
      _devCode = res['dev_code']?.toString();
      
      if (_devCode != null) {
        Notifier.success('OTP Sent! Code: $_devCode');
        // Auto-fill for convenience if desired, or let user type
        // _codeCtl.text = _devCode!; 
      } else {
        Notifier.success('OTP sent successfully');
      }

      setState(() {
        _step = 1; // Move to OTP step
      });
      // Requests focus for OTP input immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    } catch (e) {
      Notifier.error(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtl.text.trim();
    final code = _codeCtl.text.trim();

    if (code.length != 4) {
      Notifier.error('Please enter the 4-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient.verifyOtp(phone, code);
      // Ensure we navigate to the main app on success
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      }
    } catch (e) {
      Notifier.error(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBack() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      // Maybe exit app or standard back?
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Figma design uses clean white
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FinPadi_TextPrimary),
          onPressed: _onBack,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _step == 0 ? _buildPhoneStep() : _buildOtpStep(),
                ),
              ),
              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                      ? null 
                      : (_step == 0 ? _requestOtp : _verifyOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FinPadi_NavyBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Pill shape from Figma
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                          _step == 0 ? 'Continue' : 'Verify',
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ),
              // Numeric Keypad is handled by System Keyboard on specific input focus
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: FinPadi_TextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This would be securely used to verify your identity.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: FinPadi_TextSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        
        // Custom Input Field styling from Figma
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: FinPadi_Border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Flag or basic prefix icon can go here if needed
              // For now standard text input
              Expanded(
                child: TextField(
                  controller: _phoneCtl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: FinPadi_TextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Input Your Phone Number',
                    hintStyle: GoogleFonts.inter(color: FinPadi_TextLabel),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    // Optional clear button
                    suffixIcon: _phoneCtl.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => _phoneCtl.clear()),
                        )
                      : null,
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Helper text for status and guidance',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: FinPadi_ErrorRed, // Or secondary/primary based on state
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Verify Your Number',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: FinPadi_TextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: FinPadi_TextSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Please enter the 4 digit code sent to the mobile number below\n\n'),
              TextSpan(
                text: _phoneCtl.text,
                style: GoogleFonts.inter(
                  color: FinPadi_ActionOrange, 
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        // 4-Digit Code Input Custom Widget
        GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(_focusNode);
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return _buildDigitBox(index);
              }),
            ),
          ),
        ),
        
        // Hidden TextField to capture input
        SizedBox(
          height: 0,
          width: 0,
          child: TextField(
            controller: _codeCtl,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              setState(() {});
              if (val.length == 4) {
                // Optional: Auto-submit
                // _verifyOtp();
              }
            },
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive SMS? ",
              style: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextSecondary),
            ),
            GestureDetector(
              onTap: _requestOtp,
              child: Text(
                'Resend Code',
                style: GoogleFonts.inter(
                  fontSize: 14, 
                  color: FinPadi_ActionOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        if (_devCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'DEV: Code is $_devCode',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDigitBox(int index) {
    String char = '';
    if (index < _codeCtl.text.length) {
      char = _codeCtl.text[index];
    }
    
    final isActive = index == _codeCtl.text.length;
    final isFilled = index < _codeCtl.text.length;

    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? FinPadi_NavyBlue : (isFilled ? FinPadi_NavyBlue : Colors.grey[200]),
        borderRadius: BorderRadius.circular(12),
        // Applying Figma style: filled box logic or outline logic
        // The image shows boxes that look like dark squares when filled or active?
        // Actually, looking at "Sign Up 3" in provided image:
        // They are dark Navy squares with white text inside.
        // So default empty might be light grey, filled/active is Navy.
      ),
      child: Text(
        char,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
