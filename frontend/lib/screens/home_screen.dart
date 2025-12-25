import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _pendingPaise = 0;
  int _investedPaise = 0;
  List<dynamic> _txs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final port = await ApiClient.portfolio();
      final pending = await ApiClient.pendingRoundups();
      final txs = await ApiClient.transactions(limit: 10, offset: 0);
      setState(() {
        _pendingPaise = (pending['total_paise'] as num?)?.toInt() ?? 0;
        _investedPaise = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        _txs = txs;
      });
    } catch (e) {
      if (mounted) Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSampleTxn() async {
    try {
      await ApiClient.createTransaction(247.00, merchant: 'Shop');
      if (!mounted) return;
      Notifier.success('Transaction added');
      _load();
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    }
  }

  Future<void> _executeSweep() async {
    try {
      final r = await ApiClient.executeSweep();
      if (!mounted) return;
      Notifier.success('Sweep: ${r['status'] ?? 'done'}');
      _load();
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _pendingPaise + _investedPaise;
    return Scaffold(
      appBar: AppBar(title: const Text('Roundup Investing')),
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
                    const Text('Portfolio Total'),
                    _loading
                        ? Skeleton.box(height: 24, width: 120)
                        : Text(_fmt.format(total / 100.0), style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                if (_loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _loading
                    ? Skeleton.box(height: 14, width: 180)
                    : Text('Pending: ${_fmt.format(_pendingPaise/100.0)}'),
                _loading
                    ? Skeleton.box(height: 14, width: 180)
                    : Text('Invested: ${_fmt.format(_investedPaise/100.0)}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _addSampleTxn, icon: const Icon(Icons.add_shopping_cart), label: const Text('Add Tx ₹247.00'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: _executeSweep, icon: const Icon(Icons.savings), label: const Text('Execute Sweep'))),
            ]),
            const SizedBox(height: 16),
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading) ...Skeleton.tiles(6) else ..._txs.map((t) {
              final m = t as Map<String, dynamic>;
              final amtPaise = (m['amount_paise'] as num?)?.toInt() ?? 0;
              final merch = (m['merchant'] as String?) ?? 'Txn ${m['id']}';
              return ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(merch),
                trailing: Text(_fmt.format(amtPaise/100.0), style: const TextStyle(fontWeight: FontWeight.w600)),
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
