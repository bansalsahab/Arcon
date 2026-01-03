import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/screens/notifications_screen.dart';
import 'package:roundup_app/screens/kyc_screen.dart';
import 'package:roundup_app/screens/mandates_screen.dart';
import 'package:roundup_app/screens/ai_advice_screen.dart'; // Added import

class HomeScreenEnhanced extends StatefulWidget {
  const HomeScreenEnhanced({super.key});

  @override
  State<HomeScreenEnhanced> createState() => _HomeScreenEnhancedState();
}

class _HomeScreenEnhancedState extends State<HomeScreenEnhanced> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  bool _loading = false;
  
  // Data States
  Map<String, dynamic>? _userData;
  int _pendingPaise = 0;
  int _investedPaise = 0;
  List<dynamic> _txs = [];
  
  // New States for Redesign
  String _kycStatus = 'pending';
  bool _investingPaused = false;
  bool _hasActiveMandate = false;
  int _monthInvestedPaise = 0;
  int _monthTransactionCount = 0;
  String _riskTier = 'medium';
  
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Create futures but handle potential failures for newer endpoints
      final Future<dynamic> capsFuture = ApiClient.getCaps(); 
      final Future<dynamic> portFuture = ApiClient.portfolio();
      final Future<dynamic> pendingFuture = ApiClient.pendingRoundups();
      final Future<dynamic> txsFuture = ApiClient.transactions(limit: 3, offset: 0);
      final Future<dynamic> userFuture = ApiClient.me();
      final Future<dynamic> settingsFuture = ApiClient.getSettings();
      final Future<dynamic> mandateFuture = ApiClient.listMandates();
      final Future<dynamic> monthFuture = ApiClient.getMonthlySummary();

      final results = await Future.wait([
        userFuture,
        portFuture,
        pendingFuture,
        txsFuture,
        settingsFuture,
        mandateFuture,
        monthFuture.catchError((_) => {'month_invested_paise': 0, 'month_transaction_count': 0}),
        capsFuture.catchError((_) => {'investing_paused': false}), 
      ]);

      setState(() {
        _userData = results[0];
        _kycStatus = _userData?['kyc_status'] ?? 'pending';
        
        final port = results[1];
        _investedPaise = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        
        final pending = results[2];
        _pendingPaise = (pending['total_paise'] as num?)?.toInt() ?? 0;
        
        _txs = results[3];
        
        final settings = results[4];
        _riskTier = settings['risk_tier'] ?? 'medium';
        
        final mandates = results[5] as List<dynamic>;
        // Check for ANY active mandate
        _hasActiveMandate = mandates.any((m) => m['status'] == 'active' || m['status'] == 'authorized');
        
        final monthStats = results[6];
        _monthInvestedPaise = (monthStats['month_invested_paise'] as num?)?.toInt() ?? 0;
        _monthTransactionCount = (monthStats['month_transaction_count'] as num?)?.toInt() ?? 0;
        
        final caps = results[7];
        _investingPaused = (caps['investing_paused'] as bool?) ?? false;
      });
    } catch (e) {
      if (mounted) Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePause(bool pause) async {
    try {
      await ApiClient.updateCaps(investingPaused: pause);
      Notifier.success(pause ? 'Auto-invest paused' : 'Auto-invest resumed');
      _load();
    } catch (e) {
      Notifier.error(e.toString());
    }
  }
  
  Future<void> _addSampleTxn() async {
    setState(() => _loading = true);
    try {
      await ApiClient.createTransaction(247.00, merchant: 'Sample Store');
      if (!mounted) return;
      Notifier.success('Sample Transaction added!');
      _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString());
    } finally {
       if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['full_name'] as String? ?? 'User';
    final firstName = userName.split(' ').first;
    
    // determine state
    bool kycVerified = _kycStatus.toLowerCase() == 'verified' || _kycStatus.toLowerCase() == 'approved';
    
    return Scaffold(
      backgroundColor: FinPadi_Background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // 1. Header with Greeting & Bell
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                             _getGreeting(),
                             style: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName,
                            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: FinPadi_MidnightBlue),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: FinPadi_Border, width: 0.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: FinPadi_MidnightBlue, size: 22),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_loading && _investedPaise == 0) // Only show full loader on initial load
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else ...[
                // 2. Auto-Invest Status Badge
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStatusIndicator(kycVerified),
                  ),
                ),
                
                // 3. Contextual CTA Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: _buildContextualCard(kycVerified),
                  ),
                ),
                
                // 4. This Month's Spare Change
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildMonthlyProgressCard(),
                  ),
                ),
                
                // 5. Next Auto-Invest (Conditional)
                if (_hasActiveMandate && !_investingPaused && _pendingPaise > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: _buildNextDebitCard(),
                    ),
                  ),

                // 6. Portfolio Snapshot
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildPortfolioSnapshot(),
                  ),
                ),
                
                // 7. AI Insight
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildAiInsightCard(),
                  ),
                ),
                
                // 8. Recent Activity Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Activity', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: FinPadi_MidnightBlue)),
                      ],
                    ),
                  ),
                ),
                
                // 9. Transaction List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                         if (_txs.isEmpty) return _buildEmptyState('No transactions yet');
                         return _buildTransactionItem(_txs[index]);
                      },
                      childCount: _txs.isEmpty ? 1 : _txs.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildStatusIndicator(bool kycVerified) {
    Color color;
    String text;
    IconData icon;
    
    if (!kycVerified) {
      color = FinPadi_ActionOrange; // Action required
      text = 'Action Required';
      icon = Icons.warning_amber_rounded;
    } else if (!_hasActiveMandate) {
       color = FinPadi_ActionOrange;
       text = 'Setup Required';
       icon = Icons.warning_amber_rounded;
    } else if (_investingPaused) {
      color = const Color(0xFF64748B); // Slate (Paused)
      text = 'Auto-Invest Paused';
      icon = Icons.pause_circle_outline_rounded;
    } else {
      color = FinPadi_SuccessGreen;
      text = 'Auto-Invest Active';
      icon = Icons.check_circle_outline_rounded;
    }
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextualCard(bool kycVerified) {
    // 4 States for Primary Card
    String title;
    String subtitle;
    String btnText;
    VoidCallback onTap;
    
     if (!kycVerified) {
      title = 'Verify Identity';
      subtitle = 'Complete KYC to start investing securely.';
      btnText = 'Verify Now';
      onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
     } else if (!_hasActiveMandate) {
       title = 'Start Investing';
       subtitle = 'Enable AutoPay to automate your savings.';
       btnText = 'Set Up AutoPay';
       onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MandatesScreen()));
     } else if (_investingPaused) {
       title = 'Resume Savings';
       subtitle = 'You paused investing. Resuming is easy.';
       btnText = 'Resume Auto-Invest';
       onTap = () => _togglePause(false);
     } else {
       // Active State - Show Portfolio Value instead of Action
       return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [FinPadi_MidnightBlue, Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
               BoxShadow(color: FinPadi_MidnightBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: FinPadi_ElectricTeal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Total Portfolio', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _fmt.format(_investedPaise / 100).replaceAll('.00', ''),
                style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _togglePause(true),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addSampleTxn,
                      icon: const Icon(Icons.add_card, size: 16),
                      label: const Text('Add Money'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinPadi_ElectricTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
       );
     }
     
     // Render Action Card for Non-Active States
     return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FinPadi_Border),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: FinPadi_MidnightBlue)),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextSecondary, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FinPadi_MidnightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: FinPadi_MidnightBlue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(btnText, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
     );
  }
  
  Widget _buildMonthlyProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FinPadi_Border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("This Month's Drop", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: FinPadi_MidnightBlue)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: FinPadi_ElectricTeal.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.savings_outlined, color: FinPadi_ElectricTeal, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
               Text(
                 _fmt.format(_monthInvestedPaise / 100).replaceAll('.00', ''),
                 style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: FinPadi_ElectricTeal),
               ),
               Padding(
                 padding: const EdgeInsets.only(bottom: 6, left: 8),
                 child: Text('invested', style: GoogleFonts.inter(fontSize: 13, color: FinPadi_TextSecondary)),
               ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'from $_monthTransactionCount purchases',
            style: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.4, // placeholder value as we don't have a target
              backgroundColor: FinPadi_Background,
              valueColor: AlwaysStoppedAnimation<Color>(FinPadi_ElectricTeal.withOpacity(0.6)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNextDebitCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FinPadi_Background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinPadi_Border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
             child: const Icon(Icons.calendar_today_rounded, size: 18, color: FinPadi_TextSecondary),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Next Auto-Invest', style: GoogleFonts.inter(fontSize: 11, color: FinPadi_TextSecondary)),
                 Text('${_fmt.format(_pendingPaise/100)} upcoming', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: FinPadi_MidnightBlue)),
               ],
             ),
           ),
           const Icon(Icons.chevron_right, size: 18, color: FinPadi_TextSecondary),
        ],
      ),
    );
  }
  
  Widget _buildPortfolioSnapshot() {
     // Simple percentages based on risk tier
     int equity = 50, debt = 30, gold = 20;
     if (_riskTier == 'conservative') { equity = 30; debt = 50; gold = 20; }
     if (_riskTier == 'growth') { equity = 70; debt = 20; gold = 10; }
     
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text('Your Portfolio', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: FinPadi_MidnightBlue)),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
               decoration: BoxDecoration(
                 color: FinPadi_ElectricTeal.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(_riskTier.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: FinPadi_ElectricTeal)),
             ),
           ],
         ),
         const SizedBox(height: 16),
         Row(
           children: [
             Expanded(child: _buildAssetMetric('Equity', '$equity%', FinPadi_ElectricTeal)),
             Container(width: 1, height: 30, color: FinPadi_Border),
             Expanded(child: _buildAssetMetric('Debt', '$debt%', const Color(0xFF6366F1))),
             Container(width: 1, height: 30, color: FinPadi_Border),
             Expanded(child: _buildAssetMetric('Gold', '$gold%', const Color(0xFFF59E0B))),
           ],
         ),
       ],
     );
  }
  
  Widget _buildAssetMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: FinPadi_TextSecondary)),
      ],
    );
  }
  
  Widget _buildAiInsightCard() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
           MaterialPageRoute(builder: (_) => const AiAdviceScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Icon(Icons.psychology_alt_rounded, color: Color(0xFF8B5CF6), size: 20),
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 'Great consistent progress! You are investing in small steps that add up to big savings.',
                 style: GoogleFonts.inter(fontSize: 13, color: FinPadi_MidnightBlue, height: 1.4),
               ),
             ),
             const Icon(Icons.chevron_right, size: 18, color: FinPadi_TextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final amount = tx['amount'] as double;
    final roundup = tx['roundup_amount'] as double;
    final merchant = tx['merchant'] ?? 'Merchant';
    final date = DateTime.tryParse(tx['created_at']) ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinPadi_Border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: FinPadi_Background, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.storefront_outlined, color: FinPadi_TextSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchant, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: FinPadi_MidnightBlue)),
                Text(DateFormat('d MMM, h:mm a').format(date), style: GoogleFonts.inter(fontSize: 12, color: FinPadi_TextSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${_fmt.format(roundup)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: FinPadi_ElectricTeal)),
              Text('invested', style: GoogleFonts.inter(fontSize: 11, color: FinPadi_TextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: FinPadi_Border)),
      child: Center(child: Text(msg, style: GoogleFonts.inter(color: FinPadi_TextSecondary))),
    );
  }
}
