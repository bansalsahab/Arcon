import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/widgets/portfolio_chart.dart';
import 'package:roundup_app/widgets/compliance_disclaimer.dart';

class PortfolioScreenEnhanced extends StatefulWidget {
  const PortfolioScreenEnhanced({super.key});

  @override
  State<PortfolioScreenEnhanced> createState() => _PortfolioScreenEnhancedState();
}

class _PortfolioScreenEnhancedState extends State<PortfolioScreenEnhanced> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _pending = 0;
  int _invested = 0;
  Map<String, dynamic> _positions = {};
  String _riskTier = 'medium';
  List<dynamic> _redemptions = [];
  bool _redeeming = false;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final port = await ApiClient.portfolio();
      final settings = await ApiClient.getSettings();
      final reds = await ApiClient.listRedemptions(limit: 50);
      final orders = await ApiClient.listInvestments(limit: 50);
      setState(() {
        _pending = (port['pending_roundups_paise'] as num?)?.toInt() ?? 0;
        _invested = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        _positions = (port['positions_paise'] as Map?)?.cast<String, dynamic>() ?? {};
        _riskTier = (settings['risk_tier'] as String?) ?? 'medium';
        _redemptions = reds;
        _orders = orders;
      });
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
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
          title: Text('Redeem Funds', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the amount you wish to withdraw to your bank account.',
                  style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctl,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v){
                    if (v==null || v.trim().isEmpty) return 'Enter amount';
                    final d = double.tryParse(v.trim());
                    if (d==null || d<=0) return 'Enter valid amount';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Banking_TextColorSecondary)),
            ),
            ElevatedButton(
              onPressed: _redeeming ? null : () async {
                if (!formKey.currentState!.validate()) return;
                final d = double.parse(ctl.text.trim());
                setState(() => _redeeming = true);
                try {
                  await ApiClient.redeem(amountPaise: (d*100).round());
                  Notifier.success('Redemption placed successfully');
                  if (mounted) Navigator.of(ctx).pop();
                  await _load();
                } catch (e) {
                  Notifier.error(e.toString(), error: e);
                } finally {
                  if (mounted) setState(() => _redeeming = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Banking_Primary),
              child: _redeeming 
                ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2, color: Colors.white)) 
                : Text('Redeem', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _pending + _invested;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: FinPadi_Background,
      appBar: AppBar(
        title: Text('My Portfolio', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
              onPressed: _loading ? null : _showRedeemDialog,
              icon: const Icon(Icons.outbound_rounded, size: 20),
              color: FinPadi_TextSecondary,
              tooltip: 'Redeem Funds',
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            // Total Value Card (Hero)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FinPadi_MidnightBlue, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: FinPadi_MidnightBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pie_chart_outline, color: FinPadi_ElectricTeal, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Value',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FinPadi_ElectricTeal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FinPadi_ElectricTeal.withOpacity(0.3)),
                        ),
                        child: Text(
                          _riskTier.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: FinPadi_ElectricTeal,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
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
                                text: _fmt.format(total / 100.0).replaceAll('₹', ''),
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invested',
                              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loading ? '--' : _fmt.format(_invested / 100.0),
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Roundups',
                              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loading ? '--' : _fmt.format(_pending / 100.0),
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Asset Allocation Chart
            _buildSectionHeader('Asset Allocation'),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: FinPadi_MidnightBlue))
                  : PortfolioChart(positions: _positions),
            ),
            const SizedBox(height: 32),

            // Holdings List
            _buildSectionHeader('Holdings'),
            if (_loading)
              ...Skeleton.tiles(3)
            else if (_positions.isEmpty)
              _buildEmptyState(
                icon: Icons.pie_chart_outline,
                message: 'No investments yet',
                subMessage: 'Start investing to see your holdings',
              )
            else
              ..._positions.entries.map((e) => _buildHoldingItem(e)),
            
            const SizedBox(height: 32),

            // Compliance
            const ComplianceDisclaimer(
              title: 'Digital Gold Notice',
              message:
                  'Digital gold investments are not regulated by SEBI. Please ensure you understand the risks involved.',
              icon: Icons.warning_amber_rounded,
              color: Color(0xFFB45309), // Amber 700
            ),
            
            const SizedBox(height: 24),
            Divider(color: FinPadi_Border),
            const SizedBox(height: 24),

            // Investment Orders
            _buildSectionHeader('Recent Orders'),
            if (_loading && _orders.isEmpty) ...Skeleton.tiles(3)
            else if (_orders.isEmpty) 
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                 child: Text('No investment orders yet.', style: GoogleFonts.inter(color: FinPadi_TextSecondary))
               )
            else ..._orders.take(5).map((o) => _buildOrderItem(o)),

            const SizedBox(height: 32),
            _buildSectionHeader('Redemptions'),
            if (_loading && _redemptions.isEmpty) ...Skeleton.tiles(3)
            else if (_redemptions.isEmpty) 
              Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                 child: Text('No redemptions yet.', style: GoogleFonts.inter(color: FinPadi_TextSecondary))
               )
            else ..._redemptions.take(5).map((r) => _buildRedemptionItem(r)),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: FinPadi_MidnightBlue,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message, required String subMessage}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinPadi_Border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: FinPadi_TextSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.outfit(color: FinPadi_TextSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: GoogleFonts.inter(color: FinPadi_TextSecondary.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingItem(MapEntry<String, dynamic> e) {
    final k = e.key;
    final v = (e.value as num?)?.toInt() ?? 0;
    final percentage = _invested > 0
        ? (v / _invested * 100).toStringAsFixed(1)
        : '0.0';

    IconData icon;
    Color color;
    if (k.toLowerCase().contains('equity')) {
      icon = Icons.trending_up;
      color = FinPadi_ElectricTeal;
    } else if (k.toLowerCase().contains('debt')) {
      icon = Icons.security;
      color =  const Color(0xFF6366F1); // Indigo
    } else if (k.toLowerCase().contains('gold')) {
      icon = Icons.diamond_outlined;
      color = const Color(0xFFF59E0B); // Gold/Amber
    } else {
      icon = Icons.category_outlined;
      color = FinPadi_Success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: FinPadi_MidnightBlue,
                  ),
                ),
                Text(
                  '$percentage% of portfolio',
                  style: GoogleFonts.inter(
                    color: FinPadi_TextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmt.format(v / 100.0),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: FinPadi_MidnightBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic o) {
    final m = o as Map<String, dynamic>;
    final amt = (m['amount_paise'] as num?)?.toInt() ?? 0;
    final status = m['status']?.toString() ?? '';
    final pt = m['product_type']?.toString() ?? '';
    final at = m['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FinPadi_Success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline, color: FinPadi_Success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pt.toUpperCase()} Purchase',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: FinPadi_MidnightBlue),
                ),
                Text(at, style: GoogleFonts.inter(color: FinPadi_TextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt.format(amt/100.0), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: FinPadi_MidnightBlue)),
              Text(status.toUpperCase(), style: GoogleFonts.outfit(color: FinPadi_Success, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionItem(dynamic r) {
    final amt = (r['amount_paise'] as num?)?.toInt() ?? 0;
    final status = r['status']?.toString() ?? '';
    final at = r['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FinPadi_MidnightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.outbound, color: FinPadi_MidnightBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: FinPadi_MidnightBlue),
                ),
                Text(at, style: GoogleFonts.inter(color: FinPadi_TextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(_fmt.format(amt/100.0), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: FinPadi_MidnightBlue)),
        ],
      ),
    );
  }
}
