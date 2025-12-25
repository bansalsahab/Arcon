import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:bankingapp/banking/utils/BankingColors.dart';
import 'package:bankingapp/banking/utils/BankingWidget.dart';
import 'package:bankingapp/services/api.dart';
import 'package:intl/intl.dart';

class RoundupsScreen extends StatefulWidget {
  const RoundupsScreen({Key? key}) : super(key: key);

  @override
  State<RoundupsScreen> createState() => _RoundupsScreenState();
}

class _RoundupsScreenState extends State<RoundupsScreen> {
  bool _loading = false;
  int _totalPaise = 0;
  List<dynamic> _items = [];
  final NumberFormat _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

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
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createMandate() async {
    try {
      await ApiClient.createMandate();
      toast('Mandate created');
    } catch (e) {
      toast(e.toString());
    }
  }

  Future<void> _execute() async {
    try {
      final r = await ApiClient.executeSweep();
      toast('Execute: ${r['status'] ?? 'done'}');
      _load();
    } catch (e) {
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Banking_app_Background,
      appBar: AppBar(title: const Text('Roundups')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pending Total', style: primaryTextStyle(size: 18)),
                if (_loading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            8.height,
            Text(_fmt.format(_totalPaise / 100.0), style: boldTextStyle(size: 28)),
            12.height,
            Row(
              children: [
                Expanded(
                  child: BankingButton(
                    textContent: 'Create Mandate',
                    onPressed: _createMandate,
                  ),
                ),
                12.width,
                Expanded(
                  child: BankingButton(
                    textContent: 'Execute',
                    onPressed: _execute,
                  ),
                ),
              ],
            ),
            16.height,
            Divider(),
            8.height,
            Text('Items', style: primaryTextStyle(size: 16)),
            8.height,
            ..._items.map((e) {
              final m = e as Map<String, dynamic>;
              final amt = (m['amount_paise'] as num?)?.toInt() ?? 0;
              final created = (m['created_at'] as String?) ?? '';
              return Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: boxDecorationRoundedWithShadow(8, backgroundColor: Banking_whitePureColor, spreadRadius: 0, blurRadius: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(created, style: secondaryTextStyle()),
                    Text(_fmt.format(amt / 100.0), style: primaryTextStyle(color: Banking_Primary)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
