import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/widgets/compliance_disclaimer.dart';
import 'package:roundup_app/screens/mandates_screen.dart';
import 'package:roundup_app/screens/settings_screen.dart';

class RoundupsScreenEnhanced extends StatefulWidget {
  const RoundupsScreenEnhanced({super.key});

  @override
  State<RoundupsScreenEnhanced> createState() => _RoundupsScreenEnhancedState();
}

class _RoundupsScreenEnhancedState extends State<RoundupsScreenEnhanced> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _totalPaise = 0;
  List<dynamic> _items = [];
  bool _paused = false;
  bool _hasActiveMandate = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.pendingRoundups();
      final caps = await ApiClient.getCaps();
      final mandates = await ApiClient.listMandates();
      setState(() {
        _totalPaise = (data['total_paise'] as num?)?.toInt() ?? 0;
        _items = (data['items'] as List?) ?? [];
        _paused = (caps['investing_paused'] as bool?) ?? false;
        _hasActiveMandate = (mandates as List<dynamic>).any((m){
          final mm = m as Map<String, dynamic>;
          return (mm['status']?.toString() ?? '') == 'active';
        });
      });
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createMandate() async {
    try {
      await ApiClient.createMandate();
      if (!mounted) return;
      Notifier.success('UPI mandate created successfully');
      _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    }
  }

  Future<void> _execute() async {
    // Compliance gate
    final ok = await _ensureCompliance();
    if (!ok) return;
    try {
      final r = await ApiClient.executeSweep();
      if (!mounted) return;
      Notifier.success('Investment executed: ${r['status'] ?? 'completed'}');
      _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    }
  }

  Future<void> _executeAllocated() async {
    // Compliance gate
    final ok = await _ensureCompliance();
    if (!ok) return;
    try {
      final r = await ApiClient.executeAllocated();
      if (!mounted) return;
      Notifier.success('Allocated investment: ${(r['orders']?.length ?? 0)} orders');
      _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    }
  }

  Future<bool> _ensureCompliance() async {
    try {
      final hist = await ApiClient.complianceHistory();
      final msgs = hist.map((e) => (e['message']?.toString() ?? '').toLowerCase()).toList();
      final hasSebi = msgs.any((m) => m.contains('sebi'));
      final hasGold = msgs.any((m) => m.contains('gold'));
      if (hasSebi && hasGold) return true;

      bool agreed = false;
      await showDialog(
        context: context,
        builder: (ctx) {
          bool _agreeSebi = hasSebi;
          bool _agreeGold = hasGold;
          return StatefulBuilder(builder: (ctx, setS) {
            return AlertDialog(
              title: Text('Required Acknowledgements', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _agreeSebi,
                    onChanged: (v) => setS(() => _agreeSebi = v ?? false),
                    title: Text('SEBI Disclaimer', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text('I acknowledge risks and understand scheme-related documents.', style: GoogleFonts.outfit(fontSize: 12)),
                    activeColor: Banking_Primary,
                  ),
                  CheckboxListTile(
                    value: _agreeGold,
                    onChanged: (v) => setS(() => _agreeGold = v ?? false),
                    title: Text('Digital Gold Risk', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text('I understand digital gold is not SEBI-regulated.', style: GoogleFonts.outfit(fontSize: 12)),
                    activeColor: Banking_Primary,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: (){ Navigator.of(ctx).pop(); }, 
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Banking_TextColorSecondary))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Banking_Primary),
                  onPressed: (! _agreeSebi || ! _agreeGold) ? null : () async {
                    try {
                      if (!hasSebi) { await ApiClient.acceptCompliance('sebi'); }
                      if (!hasGold) { await ApiClient.acceptCompliance('gold_risk'); }
                      agreed = true;
                    } catch (_) {}
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text('Agree & Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                )
              ],
            );
          });
        },
      );
      return agreed;
    } catch (_) {
      return true; // fail open to not block UX if history fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Banking_app_Background,
      appBar: AppBar(
        title: Text('Roundups', style: GoogleFonts.outfit(color: Banking_TextColorPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Banking_app_Background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Banking_TextColorPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MandatesScreen()),
              );
            },
            tooltip: 'View Mandates',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_paused)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Banking_ErrorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Banking_ErrorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pause_circle_outline, color: Banking_ErrorRed),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Investing is currently paused.', style: GoogleFonts.outfit(color: Banking_ErrorRed, fontWeight: FontWeight.w600))),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                      child: Text('Settings', style: GoogleFonts.outfit(color: Banking_ErrorRed, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            
            if (!_hasActiveMandate)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Banking_WarningYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Banking_WarningYellow.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Banking_WarningYellow),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No active AutoPay mandate found.',
                        style: GoogleFonts.outfit(color: const Color(0xFFB56A00), fontWeight: FontWeight.w600),
                      )
                    ),
                    TextButton(
                      onPressed: _loading ? null : _createMandate,
                      child: Text('Setup', style: GoogleFonts.outfit(color: const Color(0xFFB56A00), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              
            // Pending Amount Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Banking_SuccessGreen, Color(0xFF69C06D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Banking_SuccessGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.savings_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pending Roundups',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _fmt.format(_totalPaise / 100.0),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to invest • ${_items.length} transactions',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _createMandate,
                    icon: const Icon(Icons.add_card, size: 20),
                    label: const Text('Setup UPI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Banking_Secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading || _paused || !_hasActiveMandate ? null : _execute,
                    icon: const Icon(Icons.rocket_launch, size: 20),
                    label: const Text('Invest Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Banking_Primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Banking_Primary.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading || _paused || !_hasActiveMandate ? null : _executeAllocated,
                icon: const Icon(Icons.pie_chart_outline, size: 20),
                label: const Text('Invest by Smart Allocation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Banking_Primary,
                  side: const BorderSide(color: Banking_Primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pre-debit notification
            const ComplianceDisclaimer(
              title: 'RBI Mandate Compliance',
              message:
                  'You will receive a notification 24 hours before any UPI debit as per RBI guidelines. You can pause or cancel the mandate anytime.',
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 32),

            // Roundup Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Roundup History',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Banking_TextColorPrimary,
                  ),
                ),
                if (_items.isNotEmpty)
                  Text(
                    '${_items.length} items',
                    style: GoogleFonts.outfit(
                      color: Banking_TextColorSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              ...Skeleton.tiles(6)
            else if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Banking_Border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.add_chart_outlined,
                          size: 48, color: Banking_TextColorSecondary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No pending roundups',
                        style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your spare change will appear here',
                        style: GoogleFonts.outfit(color: Banking_TextColorSecondary.withOpacity(0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._items.map((e) {
                final m = e as Map<String, dynamic>;
                final amt = (m['amount_paise'] as num?)?.toInt() ?? 0;
                final ts = (m['created_at'] as String?) ?? '';
                final txId = m['transaction_id'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Banking_Border.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Banking_SuccessGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Banking_SuccessGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Roundup #$txId',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Banking_TextColorPrimary,
                              ),
                            ),
                            if (ts.isNotEmpty)
                              Text(
                                ts,
                                style: GoogleFonts.outfit(
                                  color: Banking_TextColorSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _fmt.format(amt / 100.0),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Banking_SuccessGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
