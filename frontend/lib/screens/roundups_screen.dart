import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';

class RoundupsScreen extends StatefulWidget {
  const RoundupsScreen({super.key});

  @override
  State<RoundupsScreen> createState() => _RoundupsScreenState();
}

class _RoundupsScreenState extends State<RoundupsScreen> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _totalPaise = 0;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.pendingRoundups();
      setState(() {
        _totalPaise = (data['total_paise'] as num?)?.toInt() ?? 0;
        _items = (data['items'] as List?) ?? [];
      });
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createMandate() async {
    try {
      await ApiClient.createMandate();
      if (!mounted) return; Notifier.success('Mandate created');
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    }
  }

  Future<void> _execute() async {
    try {
      final r = await ApiClient.executeSweep();
      if (!mounted) return; Notifier.success('Execute: ${r['status'] ?? 'done'}');
      _load();
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roundups')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pending Total'),
                    _loading
                        ? Skeleton.box(height: 24, width: 140)
                        : Text(_fmt.format(_totalPaise / 100.0), style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                if (_loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _loading ? null : _createMandate, child: const Text('Create Mandate'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _loading ? null : _execute, child: const Text('Execute'))),
            ]),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading) ...Skeleton.tiles(6) else ..._items.map((e) {
              final m = e as Map<String, dynamic>;
              final amt = (m['amount_paise'] as num?)?.toInt() ?? 0;
              final ts = (m['created_at'] as String?) ?? '';
              return ListTile(
                leading: const Icon(Icons.add_chart_outlined),
                title: Text(ts),
                trailing: Text(_fmt.format(amt/100.0), style: const TextStyle(fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            }),
          ],
        ),
      ),
    );
  }
}
