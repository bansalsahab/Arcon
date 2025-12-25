import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'auth/login_screen.dart';
import 'kyc_screen.dart';
import 'mandates_screen.dart';
import 'notifications_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiClient.getSettings();
      setState(() {
        _roundingBase = (s['rounding_base'] as num?)?.toInt();
        _riskTier = (s['risk_tier'] as String?) ?? 'medium';
        _sweepFrequency = (s['sweep_frequency'] as String?) ?? 'daily';
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
    await ApiClient.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            if (_loading) Skeleton.box(height: 20, width: 220) else TextFormField(
              initialValue: _roundingBase?.toString() ?? '10',
              decoration: const InputDecoration(labelText: 'Rounding Base (₹)', hintText: '1 - 1000'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _roundingBase = int.tryParse(v),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            if (_loading) Skeleton.box(height: 20, width: 220) else DropdownButtonFormField<String>(
              value: _riskTier,
              decoration: const InputDecoration(labelText: 'Risk Tier'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (v) => setState(() => _riskTier = v ?? 'medium'),
            ),
            const SizedBox(height: 12),
            if (_loading) Skeleton.box(height: 20, width: 240) else DropdownButtonFormField<String>(
              value: _sweepFrequency,
              decoration: const InputDecoration(labelText: 'Sweep Frequency'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _sweepFrequency = v ?? 'daily'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _loading ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('Save')),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('KYC'),
            subtitle: const Text('PAN and Aadhaar last 4, verification'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined),
            title: const Text('Mandates'),
            subtitle: const Text('List, pause/resume, cancel'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MandatesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Pre-debit schedule/send, history'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
