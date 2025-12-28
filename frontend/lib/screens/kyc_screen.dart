import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/notifier.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _loading = false;
  String _status = 'not_started';
  String? _reason;
  final _panCtl = TextEditingController();
  final _aadhaarCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiClient.kycGet();
      setState(() {
        _status = (r['status'] as String?) ?? 'not_started';
        _reason = r['rejection_reason'] as String?;
      });
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final r = await ApiClient.kycStart(_panCtl.text.trim(), _aadhaarCtl.text.trim());
      setState(() {
        _status = (r['status'] as String?) ?? _status;
        _reason = r['rejection_reason'] as String?;
      });
      if (!mounted) return; Notifier.success('KYC submitted');
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally { if (mounted) setState(() => _loading = false);}  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final r = await ApiClient.kycVerify();
      setState(() {
        _status = (r['status'] as String?) ?? _status;
        _reason = r['rejection_reason'] as String?;
      });
      if (!mounted) return; Notifier.success('KYC: ${_status.toUpperCase()}');
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally { if (mounted) setState(() => _loading = false);}  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Banking_app_Background,
      appBar: AppBar(
        title: Text('Identity Verification', style: GoogleFonts.outfit(color: Banking_TextColorPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Banking_app_Background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Banking_TextColorPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildStatusCard(),
            const SizedBox(height: 32),
            if (_status == 'not_started' || _status == 'rejected') ...[
              Text(
                'Submit Documents',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Banking_TextColorPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Banking_Border),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _panCtl,
                      decoration: const InputDecoration(
                        labelText: 'PAN Number',
                        hintText: 'ABCDE1234F',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _aadhaarCtl,
                      decoration: const InputDecoration(
                        labelText: 'Aadhaar (Last 4)',
                        hintText: '1234',
                        prefixIcon: Icon(Icons.fingerprint),
                        counterText: ""
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _start,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Banking_Primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit KYC Details', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_status == 'submitted') ...[
               SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _verify,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Simulate Verification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Banking_Secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData icon;
    String title;
    String desc;

    switch (_status) {
      case 'verified':
        statusColor = Banking_SuccessGreen;
        icon = Icons.verified_user_outlined;
        title = 'Verified';
        desc = 'Your account is fully verified. You can now invest freely.';
        break;
      case 'submitted':
        statusColor = Banking_WarningYellow;
        icon = Icons.hourglass_top_outlined;
        title = 'Pending Review';
        desc = 'We are verifying your documents. This usually takes 2-3 minutes.';
        break;
      case 'rejected':
        statusColor = Banking_ErrorRed;
        icon = Icons.error_outline;
        title = 'Action Required';
        desc = _reason ?? 'Verification failed. Please check your details.';
        break;
      default:
        statusColor = Banking_Secondary;
        icon = Icons.shield_outlined;
        title = 'Not Verified';
        desc = 'Complete KYC to start your investment journey.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Banking_TextColorPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Banking_TextColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
