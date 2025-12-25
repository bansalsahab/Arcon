import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/utils/skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      final list = await ApiClient.listNotifications();
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _schedule() async {
    setState(() => _loading = true);
    try { await ApiClient.schedulePreDebit(); if (mounted) Notifier.success('Pre-debit scheduled'); await _load(); } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try { await ApiClient.sendPreDebit(); if (mounted) Notifier.success('Pre-debit sent'); await _load(); } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _loading ? null : _schedule, child: const Text('Schedule Pre-Debit'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _loading ? null : _send, child: const Text('Send Pre-Debit'))),
            ]),
            const SizedBox(height: 16),
            if (_loading && _items.isEmpty) ...Skeleton.tiles(6) else ..._items.map((e) {
              final m = e as Map<String, dynamic>;
              final type = (m['event_type'] as String?) ?? 'event';
              final msg = (m['message'] as String?) ?? '';
              final amt = (m['amount_paise'] as num?)?.toInt() ?? 0;
              final ts = (m['created_at'] as String?) ?? '';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(type),
                  subtitle: Text(msg.isEmpty ? ts : '$ts\n$msg'),
                  isThreeLine: msg.isNotEmpty,
                  trailing: amt > 0 ? Text('₹${(amt/100.0).toStringAsFixed(2)}') : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
