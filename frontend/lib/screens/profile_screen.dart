import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/screens/settings_screen.dart';
import 'package:roundup_app/screens/kyc_screen.dart';
import 'package:roundup_app/screens/mandates_screen.dart';
import 'package:roundup_app/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await ApiClient.me();
      final settings = await ApiClient.getSettings();
      setState(() {
        _userData = user;
        _settings = settings;
      });
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiClient.logout();
    Notifier.success('Logged out');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['full_name'] as String? ?? 'User';
    final phone = _userData?['phone_number'] as String? ?? '';
    final kycStatus = _userData?['kyc_status'] as String? ?? 'pending';
    final riskTier = _settings?['risk_tier'] as String? ?? 'medium';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: FinPadi_Background,
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: FinPadi_Background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: FinPadi_MidnightBlue),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FinPadi_MidnightBlue, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: FinPadi_MidnightBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: FinPadi_ElectricTeal.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: FinPadi_ElectricTeal, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: FinPadi_ElectricTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getKycColor(kycStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getKycColor(kycStatus).withOpacity(0.5)),
                    ),
                    child: Text(
                      'KYC: ${kycStatus.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getKycColor(kycStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Settings
            Text(
              'Investment Profile',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FinPadi_MidnightBlue,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Risk Tier',
              riskTier.toUpperCase(),
              Icons.assessment_outlined,
              FinPadi_ElectricTeal,
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FinPadi_MidnightBlue,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              'Settings',
              'Manage preferences',
              Icons.settings_outlined,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                );
              },
            ),
            _buildActionTile(
              'KYC Verification',
              'Complete verification',
              Icons.verified_user_outlined,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KycScreen()),
                );
              },
            ),
            _buildActionTile(
              'UPI Mandates',
              'Manage AutoPay',
              Icons.payment_outlined,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MandatesScreen()),
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FinPadi_Error,
                  side: const BorderSide(color: FinPadi_Error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: FinPadi_TextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FinPadi_MidnightBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, void Function() onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FinPadi_Background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: FinPadi_MidnightBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: FinPadi_MidnightBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: FinPadi_TextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: FinPadi_TextSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getKycColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        return FinPadi_Success;
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'rejected':
        return FinPadi_Error;
      default:
        return FinPadi_TextSecondary;
    }
  }
}
