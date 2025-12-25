import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/utils/skeleton.dart';

class MandatesScreen extends StatefulWidget {
  const MandatesScreen({super.key});

  @override
  State<MandatesScreen> createState() => _MandatesScreenState();
}

class _MandatesScreenState extends State<MandatesScreen> {
  bool _loading = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiClient.listMandates();
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pause(int id) async { await _action(() => ApiClient.pauseMandate(id)); }
  Future<void> _resume(int id) async { await _action(() => ApiClient.resumeMandate(id)); }
  Future<void> _cancel(int id) async { await _action(() => ApiClient.cancelMandate(id)); }

  Future<void> _action(Future<dynamic> Function() fn) async {
    setState(() => _loading = true);
    try { await fn(); if (mounted) Notifier.success('Action completed'); await _load(); } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mandates')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            if (_loading && _items.isEmpty) ...Skeleton.tiles(6) else ..._items.map((e) {
              final m = e as Map<String, dynamic>;
              final id = (m['id'] as num).toInt();
              final status = (m['status'] as String?) ?? 'unknown';
              final provider = m['provider'] as String? ?? 'UPI';
              final ext = m['external_mandate_id'] as String? ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mandate #$id', style: Theme.of(context).textTheme.titleMedium),
                          Chip(label: Text(status.toUpperCase())),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Provider: $provider'),
                      Text('External ID: $ext'),
                      const SizedBox(height: 8),
                      Row(children: [
                        if (status == 'active')
                          Expanded(child: OutlinedButton(onPressed: () => _pause(id), child: const Text('Pause'))),
                        if (status == 'paused')
                          Expanded(child: OutlinedButton(onPressed: () => _resume(id), child: const Text('Resume'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () => _cancel(id), child: const Text('Cancel'))),
                      ]),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
