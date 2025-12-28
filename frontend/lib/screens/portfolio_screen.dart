import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _pending = 0;
  int _invested = 0;
  Map<String, dynamic> _positions = {};
  List<dynamic> _redemptions = [];
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final port = await ApiClient.portfolio();
      final reds = await ApiClient.listRedemptions(limit: 50);
      setState(() {
        _pending = (port['pending_roundups_paise'] as num?)?.toInt() ?? 0;
        _invested = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        _positions = (port['positions_paise'] as Map?)?.cast<String, dynamic>() ?? {};
        _redemptions = reds;
      });
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRedeemDialog() async {
    final ctl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Redeem'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctl,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v){
                if (v==null || v.trim().isEmpty) return 'Enter amount';
                final d = double.tryParse(v.trim());
                if (d==null || d<=0) return 'Enter valid amount';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _redeeming ? null : () async {
                if (!formKey.currentState!.validate()) return;
                final d = double.parse(ctl.text.trim());
                setState(() => _redeeming = true);
                try {
                  await ApiClient.redeem(amountPaise: (d*100).round());
                  Notifier.success('Redemption placed');
                  if (mounted) Navigator.of(ctx).pop();
                  await _load();
                } catch (e) {
                  Notifier.error(e.toString(), error: e);
                } finally {
                  if (mounted) setState(() => _redeeming = false);
                }
              },
              child: _redeeming ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Redeem'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _showRedeemDialog,
            icon: const Icon(Icons.outbound),
            tooltip: 'Redeem',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Invested Total'),
                  _loading
                      ? Skeleton.box(height: 24, width: 140)
                      : Text(_fmt.format(_invested/100.0), style: Theme.of(context).textTheme.headlineSmall),
                ]),
                if (_loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            _loading
                ? Skeleton.box(height: 14, width: 200)
                : Text('Pending: ${_fmt.format(_pending/100.0)}'),
            const SizedBox(height: 16),
            Text('Positions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading) ...Skeleton.tiles(6) else ..._positions.entries.map((e) {
              final k = e.key; final v = (e.value as num?)?.toInt() ?? 0;
              return ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(k),
                trailing: Text(_fmt.format(v/100.0), style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('Redemptions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading && _redemptions.isEmpty) ...Skeleton.tiles(5)
            else if (_redemptions.isEmpty) const Text('No redemptions yet.')
            else ..._redemptions.map((r){
              final amt = (r['amount_paise'] as num?)?.toInt() ?? 0;
              final status = r['status']?.toString() ?? '';
              final at = r['created_at']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(_fmt.format(amt/100.0)),
                subtitle: Text(at),
                trailing: Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            })
          ],
        ),
      ),
    );
  }
}
