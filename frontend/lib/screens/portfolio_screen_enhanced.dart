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

    return Scaffold(
      backgroundColor: Banking_app_Background,
      appBar: AppBar(
        title: Text('My Portfolio', style: GoogleFonts.outfit(color: Banking_TextColorPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Banking_app_Background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Banking_TextColorPrimary),
        actions: [
          IconButton(
            onPressed: _loading ? null : _showRedeemDialog,
            icon: const Icon(Icons.outbound_outlined),
            tooltip: 'Redeem',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Total Value Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Banking_Primary, Banking_Accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Banking_Primary.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Value',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _riskTier.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _loading
                      ? const SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _fmt.format(total / 100.0),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invested',
                              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loading ? '--' : _fmt.format(_invested / 100.0),
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Roundups',
                              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13),
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
            const SizedBox(height: 24),

            // Asset Allocation Chart
            _buildSectionHeader('Asset Allocation'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Banking_Border),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Banking_Primary))
                  : PortfolioChart(positions: _positions),
            ),
            const SizedBox(height: 24),

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
              color: Banking_WarningYellow,
            ),
            
            const SizedBox(height: 24),
            Divider(color: Banking_Border),
            const SizedBox(height: 24),

            // Investment Orders
            _buildSectionHeader('Recent Orders'),
            if (_loading && _orders.isEmpty) ...Skeleton.tiles(3)
            else if (_orders.isEmpty) const Text('No investment orders yet.')
            else ..._orders.take(5).map((o) => _buildOrderItem(o)),

            const SizedBox(height: 24),
            _buildSectionHeader('Redemptions'),
            if (_loading && _redemptions.isEmpty) ...Skeleton.tiles(3)
            else if (_redemptions.isEmpty) const Text('No redemptions yet.')
            else ..._redemptions.take(5).map((r) => _buildRedemptionItem(r)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Banking_TextColorPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message, required String subMessage}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Banking_Border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Banking_TextColorSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: GoogleFonts.outfit(color: Banking_TextColorSecondary.withOpacity(0.7), fontSize: 13),
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
      color = Banking_Accent;
    } else if (k.toLowerCase().contains('debt')) {
      icon = Icons.security;
      color = Banking_Secondary;
    } else if (k.toLowerCase().contains('gold')) {
      icon = Icons.diamond_outlined;
      color = const Color(0xFFFFD700); // Gold color
    } else {
      icon = Icons.category_outlined;
      color = Banking_SuccessGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Banking_Border.withOpacity(0.6)),
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
              borderRadius: BorderRadius.circular(12),
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Banking_TextColorPrimary,
                  ),
                ),
                Text(
                  '$percentage% of portfolio',
                  style: GoogleFonts.outfit(
                    color: Banking_TextColorSecondary,
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
              color: Banking_TextColorPrimary,
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Banking_Border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Banking_SuccessGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline, color: Banking_SuccessGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pt.toUpperCase()} Buy',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(at, style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt.format(amt/100.0), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(status.toUpperCase(), style: GoogleFonts.outfit(color: Banking_SuccessGreen, fontSize: 10, fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Banking_Border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Banking_Secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.outbound, color: Banking_Secondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(at, style: GoogleFonts.outfit(color: Banking_TextColorSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(_fmt.format(amt/100.0), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
