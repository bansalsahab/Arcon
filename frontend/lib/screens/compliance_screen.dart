import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/utils/skeleton.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  bool _loading = false;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApiClient.complianceHistory();
      setState(() => _history = items);
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String type, String label) async {
    setState(() => _loading = true);
    try {
      await ApiClient.acceptCompliance(type);
      Notifier.success('$label accepted');
      await _load();
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(onPressed: _loading ? null : () => _accept('terms', 'Terms'), icon: const Icon(Icons.article_outlined), label: const Text('Accept Terms')),
                ElevatedButton.icon(onPressed: _loading ? null : () => _accept('privacy', 'Privacy Policy'), icon: const Icon(Icons.privacy_tip_outlined), label: const Text('Accept Privacy')),
                ElevatedButton.icon(onPressed: _loading ? null : () => _accept('sebi', 'SEBI Disclaimer'), icon: const Icon(Icons.policy_outlined), label: const Text('Acknowledge SEBI')),
                ElevatedButton.icon(onPressed: _loading ? null : () => _accept('gold_risk', 'Gold Risk'), icon: const Icon(Icons.warning_amber_outlined), label: const Text('Acknowledge Gold Risk')),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading && _history.isEmpty) ...Skeleton.tiles(6)
            else if (_history.isEmpty) const Text('No compliance acceptances recorded yet.')
            else ..._history.map((e) {
              final msg = e['message']?.toString() ?? '';
              final at = e['created_at']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(msg),
                subtitle: Text(at),
              );
            }),
          ],
        ),
      ),
    );
  }
}
