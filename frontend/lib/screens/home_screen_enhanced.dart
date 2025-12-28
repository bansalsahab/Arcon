import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/widgets/stat_card.dart';

class HomeScreenEnhanced extends StatefulWidget {
  const HomeScreenEnhanced({super.key});

  @override
  State<HomeScreenEnhanced> createState() => _HomeScreenEnhancedState();
}

class _HomeScreenEnhancedState extends State<HomeScreenEnhanced> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _pendingPaise = 0;
  int _investedPaise = 0;
  List<dynamic> _txs = [];
  Map<String, dynamic>? _userData;

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
      final txs = await ApiClient.transactions(limit: 5, offset: 0);
      final user = await ApiClient.me();
      setState(() {
        _pendingPaise = (pending['total_paise'] as num?)?.toInt() ?? 0;
        _investedPaise = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        _txs = txs;
        _userData = user;
      });
    } catch (e) {
      if (mounted) Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSampleTxn() async {
    try {
      await ApiClient.createTransaction(247.00, merchant: 'Sample Store');
      if (!mounted) return;
      Notifier.success('Transaction added - ₹3 will be rounded up');
      _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    }
  }

  Future<void> _executeSweep() async {
    try {
      final r = await ApiClient.executeSweep();
      if (!mounted) return;
      Notifier.success('Sweep executed: ${r['status'] ?? 'completed'}');
      _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _pendingPaise + _investedPaise;
    final userName = _userData?['full_name'] as String? ?? 'User';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: FinPadi_Background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // Header with greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: FinPadi_TextLabel,
                            ),
                          ),
                          Text(
                            firstName,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: FinPadi_NavyBlue,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.notifications_outlined, color: FinPadi_NavyBlue, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card (FinPadi style - large prominent card)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              FinPadi_NavyBlue,
                              Color(0xFF2A4A85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: FinPadi_NavyBlue.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Balance',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _loading
                                ? const SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _fmt.format(total / 100.0),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loading ? null : _executeSweep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FinPadi_ActionOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Invest Now', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions Grid (2x2)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          _buildQuickAction('Pending', _fmt.format(_pendingPaise / 100.0), Icons.hourglass_empty_outlined, FinPadi_ActionOrange),
                          _buildQuickAction('Invested', _fmt.format(_investedPaise / 100.0), Icons.trending_up_outlined, FinPadi_SuccessGreen),
                          _buildQuickAction('Test Transaction', 'Add ₹247', Icons.add_shopping_cart_outlined, FinPadi_NavyBlue, onTap: _addSampleTxn),
                          _buildQuickAction('Transactions', '${_txs.length}', Icons.receipt_long_outlined, Color(0xFF9B51E0)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Recent Transactions Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: FinPadi_TextPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('View All', style: GoogleFonts.inter(color: FinPadi_NavyBlue, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_loading)
                        ...Skeleton.tiles(3)
                      else if (_txs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: FinPadi_Border),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 48, color: FinPadi_TextLabel.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions yet',
                                  style: GoogleFonts.inter(color: FinPadi_TextSecondary, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._txs.map((t) => _TransactionItem(t: t, fmt: _fmt)),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FinPadi_Border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: FinPadi_TextLabel,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FinPadi_TextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final dynamic t;
  final NumberFormat fmt;

  const _TransactionItem({required this.t, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final m = t as Map<String, dynamic>;
    final amtPaise = (m['amount_paise'] as num?)?.toInt() ?? 0;
    final merch = (m['merchant'] as String?) ?? 'Transaction';
    final createdAt = m['created_at'] as String?;
    
    String dateStr = 'Just now';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        dateStr = DateFormat('MMM d, h:mm a').format(date.toLocal());
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinPadi_Border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FinPadi_NavyBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: FinPadi_NavyBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merch,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: FinPadi_TextPrimary,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    color: FinPadi_TextLabel,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fmt.format(amtPaise / 100.0),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: FinPadi_TextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
