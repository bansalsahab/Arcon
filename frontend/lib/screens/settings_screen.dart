import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'auth/login_screen.dart';
import 'kyc_screen.dart';
import 'mandates_screen.dart';
import 'notifications_screen.dart';
import 'compliance_screen.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = false;
  int? _roundingBase;
  String _riskTier = 'medium';
  String _sweepFrequency = 'daily';
  bool _investingPaused = false;
  int? _dailyCapPaise;
  int? _monthlyCapPaise;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiClient.getSettings();
      final caps = await ApiClient.getCaps();
      setState(() {
        _roundingBase = (s['rounding_base'] as num?)?.toInt();
        _riskTier = (s['risk_tier'] as String?) ?? 'medium';
        _sweepFrequency = (s['sweep_frequency'] as String?) ?? 'daily';
        _investingPaused = (caps['investing_paused'] as bool?) ?? false;
        _dailyCapPaise = (caps['daily_cap_paise'] as num?)?.toInt();
        _monthlyCapPaise = (caps['monthly_cap_paise'] as num?)?.toInt();
      });
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiClient.updateSettings(roundingBase: _roundingBase, riskTier: _riskTier, sweepFrequency: _sweepFrequency);
      if (!mounted) return; Notifier.success('Settings saved');
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally { if (mounted) setState(() => _loading = false);}  }

  Future<void> _logout() async {
    await ApiClient.logout();
    Notifier.success('Logged out');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _saveCaps() async {
    setState(() => _loading = true);
    try {
      await ApiClient.updateCaps(
        investingPaused: _investingPaused,
        dailyCapPaise: _dailyCapPaise,
        monthlyCapPaise: _monthlyCapPaise,
      );
      if (!mounted) return; Notifier.success('Investing controls saved');
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Banking_app_Background,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(color: Banking_TextColorPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Banking_app_Background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Banking_TextColorPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2, color: Banking_Primary, backgroundColor: Colors.transparent),
            const SizedBox(height: 8),

            // Investment Preferences Section
            _buildSectionTitle('Investment Preferences'),
            _buildSectionCard(
              children: [
                _buildTextField(
                  label: 'Rounding Base (₹)',
                  hint: '1 - 1000',
                  initialValue: _roundingBase?.toString() ?? '10',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _roundingBase = int.tryParse(v),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Risk Tier',
                  value: _riskTier,
                  items: [
                    const DropdownMenuItem(value: 'low', child: Text('Low (Conservative)')),
                    const DropdownMenuItem(value: 'medium', child: Text('Medium (Balanced)')),
                    const DropdownMenuItem(value: 'high', child: Text('High (Aggressive)')),
                  ],
                  onChanged: (v) => setState(() => _riskTier = v ?? 'medium'),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Sweep Frequency',
                  value: _sweepFrequency,
                  items: [
                    const DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    const DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (v) => setState(() => _sweepFrequency = v ?? 'daily'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Banking_Primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Preferences', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Investing Controls Section
            _buildSectionTitle('Investing Controls'),
            _buildSectionCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Pause Investing', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  subtitle: Text('Temporarily stop all roundups', style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 13)),
                  activeColor: Banking_WarningYellow,
                  value: _investingPaused,
                  onChanged: _loading ? null : (v) => setState(() => _investingPaused = v),
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Daily Cap (₹)',
                  hint: 'Optional limit',
                  initialValue: _dailyCapPaise == null ? '' : ((_dailyCapPaise ?? 0) / 100.0).toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final t = v.trim();
                    if (t.isEmpty) { _dailyCapPaise = null; return; }
                    final d = double.tryParse(t);
                    _dailyCapPaise = d == null ? null : (d * 100).round();
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Monthly Cap (₹)',
                  hint: 'Optional limit',
                  initialValue: _monthlyCapPaise == null ? '' : ((_monthlyCapPaise ?? 0) / 100.0).toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final t = v.trim();
                    if (t.isEmpty) { _monthlyCapPaise = null; return; }
                    final d = double.tryParse(t);
                    _monthlyCapPaise = d == null ? null : (d * 100).round();
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveCaps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Banking_Secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Update Controls', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Account & App'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Banking_Border),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.badge_outlined,
                    title: 'KYC Verification',
                    subtitle: 'Manage identification documents',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycScreen())),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Mandates',
                    subtitle: 'Manage AutoPay subscriptions',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MandatesScreen())),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    subtitle: 'Pre-debit alerts & history',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Compliance & Legal',
                    subtitle: 'SEBI, Digital Gold, Terms',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComplianceScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Banking_ErrorRed,
                  side: const BorderSide(color: Banking_ErrorRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Banking_TextColorPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Banking_Border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField({required String label, required String hint, required String initialValue, required TextInputType keyboardType, required Function(String) onChanged}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(color: Banking_TextColorSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: GoogleFonts.outfit(),
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: !_loading,
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Banking_TextColorSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: GoogleFonts.outfit(color: Banking_TextColorPrimary, fontSize: 16),
      items: items,
      onChanged: _loading ? null : onChanged,
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Banking_Secondary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Banking_Secondary, size: 22),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, color: Banking_TextColorSecondary, size: 20),
      onTap: onTap,
    );
  }
}
