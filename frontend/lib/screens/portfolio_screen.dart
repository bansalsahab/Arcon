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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final port = await ApiClient.portfolio();
      setState(() {
        _pending = (port['pending_roundups_paise'] as num?)?.toInt() ?? 0;
        _invested = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        _positions = (port['positions_paise'] as Map?)?.cast<String, dynamic>() ?? {};
      });
    } catch (e) {
      if (!mounted) return; Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
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
          ],
        ),
      ),
    );
  }
}
