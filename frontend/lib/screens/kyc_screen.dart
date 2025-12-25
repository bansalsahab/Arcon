import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
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
      appBar: AppBar(title: const Text('KYC')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Status'),
                    Text(_status.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
                    if (_reason != null) const SizedBox(height: 4),
                    if (_reason != null)
                      Text('Reason: $_reason', style: const TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _panCtl,
              decoration: const InputDecoration(labelText: 'PAN (e.g., ABCDE1234F)'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aadhaarCtl,
              decoration: const InputDecoration(labelText: 'Aadhaar Last 4'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _loading ? null : _start, child: const Text('Submit KYC'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: _loading ? null : _verify, child: const Text('Verify'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
