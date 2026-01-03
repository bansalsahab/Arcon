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
import 'package:url_launcher/url_launcher.dart';

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
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enable UPI AutoPay?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automate your roundup investments with UPI AutoPay:', style: GoogleFonts.outfit(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Banking_Primary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Daily auto-debits up to ₹500', style: GoogleFonts.outfit(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Banking_Primary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('24h notice before each debit', style: GoogleFonts.outfit(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Banking_Primary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Cancel anytime', style: GoogleFonts.outfit(fontSize: 13))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Not Now', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Banking_Primary, foregroundColor: Colors.white),
            child: Text('Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final response = await ApiClient.createMandate();
      if (!mounted) return;

      final authLink = response['auth_link'] as String?;
      if (authLink != null && authLink.isNotEmpty) {
        // Real Razorpay flow
        final uri = Uri.parse(authLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (!mounted) return;
          // Show follow-up dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text('Approve in UPI App', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Text(
                'Your UPI app (GPay/PhonePe/Paytm) should open now. Please approve the AutoPay mandate to activate auto-investing.',
                style: GoogleFonts.outfit(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _load(); // Refresh to check updated status
                  },
                  child: Text('Done', style: GoogleFonts.outfit(color: Banking_Primary)),
                ),
              ],
            ),
          );
        } else {
          Notifier.error('Could not open UPI app. Try manually from Mandates screen.');
        }
      } else {
        // Mock provider or error
        Notifier.success('UPI mandate created');
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: FinPadi_Background,
      appBar: AppBar(
        title: Text('Roundups', style: theme.textTheme.titleLarge),
        backgroundColor: FinPadi_Background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: FinPadi_MidnightBlue),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 20),
              color: FinPadi_MidnightBlue,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MandatesScreen()),
                );
              },
              tooltip: 'View Mandates',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            if (_paused)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: FinPadi_Error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FinPadi_Error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pause_circle_outline, color: FinPadi_Error),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Investing is currently paused.', style: GoogleFonts.inter(color: FinPadi_Error, fontWeight: FontWeight.w600))),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                      child: Text('Settings', style: GoogleFonts.outfit(color: FinPadi_Error, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            
            if (!_hasActiveMandate)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // Amber-50
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDBA74).withOpacity(0.5)), // Amber-300
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFEA580C).withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFFEA580C)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supercharge your savings',
                            style: GoogleFonts.outfit(color: const Color(0xFF9A3412), fontWeight: FontWeight.bold, fontSize: 13), // Orange-900
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enable AutoPay to invest automatically.',
                            style: GoogleFonts.inter(color: const Color(0xFFEA580C), fontSize: 13), // Orange-600
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _createMandate,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Enable', style: GoogleFonts.outfit(color: const Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              
            // Pending Amount Card (Hero)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FinPadi_ElectricTeal, Color(0xFF0284C7)], // Cyan-500 to Sky-600
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: FinPadi_ElectricTeal.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pending Roundups',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: _fmt.format(_totalPaise / 100.0).replaceAll('₹', ''),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Ready to invest • ${_items.length} items',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                  child: ElevatedButton(
                    onPressed: _loading ? null : _createMandate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: FinPadi_MidnightBlue,
                      elevation: 0,
                      side: BorderSide(color: FinPadi_Border.withOpacity(0.8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_card, size: 18, color: FinPadi_TextSecondary),
                        const SizedBox(width: 8),
                        Text('Setup UPI', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: FinPadi_TextPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading || _paused || !_hasActiveMandate ? null : _execute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FinPadi_MidnightBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: FinPadi_MidnightBlue.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Invest Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading || _paused || !_hasActiveMandate ? null : _executeAllocated,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FinPadi_ElectricTeal,
                  side: const BorderSide(color: FinPadi_ElectricTeal),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pie_chart_outline, size: 20),
                    const SizedBox(width: 8),
                    Text('Invest by Smart Allocation', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ],
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_items.isNotEmpty)
                  Text(
                    '${_items.length} items',
                    style: GoogleFonts.inter(
                      color: FinPadi_TextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FinPadi_Background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_chart_outlined, size: 32, color: FinPadi_TextSecondary.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending roundups',
                        style: GoogleFonts.inter(color: FinPadi_TextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your spare change transaction roundups\nwill appear here automatically.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: FinPadi_TextSecondary, fontSize: 13, height: 1.5),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: FinPadi_Border.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FinPadi_Background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: FinPadi_Success,
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
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: FinPadi_TextPrimary,
                              ),
                            ),
                            if (ts.isNotEmpty) ...[
                             const SizedBox(height: 4),
                             Text(
                                ts,
                                style: GoogleFonts.inter(
                                  color: FinPadi_TextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _fmt.format(amt / 100.0),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: FinPadi_Success,
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
