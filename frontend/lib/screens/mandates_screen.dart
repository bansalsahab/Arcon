import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/theme/banking_theme.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:roundup_app/utils/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MandatesScreen extends StatefulWidget {
  const MandatesScreen({super.key});

  @override
  State<MandatesScreen> createState() => _MandatesScreenState();
}

class _MandatesScreenState extends State<MandatesScreen> {
  bool _loading = false;
  List<dynamic> _items = [];
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiClient.listMandates();
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createMandate() async {
    // Show create mandate dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const CreateMandateDialog(),
    );

    if (result == null) return;

    setState(() => _loading = true);
    
    try {
      final response = await ApiClient.createMandate();
      
      if (!mounted) return;
      
      final authLink = response['auth_link'] as String?;
      
      if (authLink != null && authLink.isNotEmpty) {
        // Launch UPI app for authorization
        final uri = Uri.parse(authLink);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          Notifier.success('Redirecting to UPI app for authorization...');
          
          // Inform user to check UPI app
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Approve in UPI App', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Text(
                'Please approve the AutoPay mandate in your UPI app (GPay/PhonePe/Paytm/Bank app) to continue.',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _load(); // Refresh to check status
                  },
                  child: Text('Done', style: GoogleFonts.inter(color: FinPadi_ActionOrange)),
                ),
              ],
            ),
          );
        } else {
          Notifier.error('Could not launch UPI app');
        }
      } else {
        // For mock provider, mandate is instantly active
        Notifier.success('Mandate created successfully');
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pause(int id) async => _action(() => ApiClient.pauseMandate(id), 'Mandate paused');
  Future<void> _resume(int id) async => _action(() => ApiClient.resumeMandate(id), 'Mandate resumed');
  Future<void> _cancel(int id) async {
    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Mandate?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently cancel the AutoPay mandate. You can create a new one anytime.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: FinPadi_ErrorRed),
            child: Text('Cancel Mandate', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _action(() => ApiClient.cancelMandate(id), 'Mandate cancelled');
    }
  }

  Future<void> _action(Future<dynamic> Function() fn, String successMsg) async {
    setState(() => _loading = true);
    try {
      await fn();
      if (mounted) Notifier.success(successMsg);
      await _load();
    } catch (e) {
      if (!mounted) return;
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinPadi_Background,
      appBar: AppBar(
        title: Text('UPI AutoPay Mandates', style: GoogleFonts.inter(color: FinPadi_TextPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: FinPadi_TextPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: FinPadi_ActionOrange,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading && _items.isEmpty) const LinearProgressIndicator(minHeight: 2, color: FinPadi_NavyBlue),
            const SizedBox(height: 8),

            // Info Card
            _buildInfoCard(),
            const SizedBox(height: 20),

            // Create Mandate Button
            if (_items.isEmpty || _items.every((m) => (m['status'] as String?) != 'active'))
              _buildCreateMandateButton(),

            const SizedBox(height: 20),

            if (_items.isEmpty && !_loading)
              _buildEmptyState()
            else if (_loading && _items.isEmpty)
              ...Skeleton.tiles(3)
            else
              ..._items.map((e) => _buildMandateCard(e)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FinPadi_NavyBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FinPadi_NavyBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: FinPadi_NavyBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'UPI AutoPay enables automatic investment debits. You\'ll receive a 24-hour notice before each debit.',
              style: GoogleFonts.inter(fontSize: 12, color: FinPadi_TextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMandateButton() {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _createMandate,
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: Text('Enable Auto-Invest', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: FinPadi_ActionOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.receipt_long_outlined, size: 64, color: FinPadi_TextSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No Active Mandates', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: FinPadi_TextPrimary)),
          const SizedBox(height: 8),
          Text('Set up AutoPay to automate your roundup investments', style: GoogleFonts.inter(color: FinPadi_TextSecondary, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMandateCard(dynamic item) {
    final m = item as Map<String, dynamic>;
    final id = (m['id'] as num).toInt();
    final status = (m['status'] as String?) ?? 'unknown';
    final frequency = (m['frequency'] as String?) ?? 'daily';
    final maxAmountPaise = (m['max_amount_paise'] as num?)?.toInt() ?? 50000;
    final nextDebitAt = m['next_debit_at'] as String?;
    final lastDebitAt = m['last_debit_at'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status Badge + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                Text(_fmt.format(maxAmountPaise / 100), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: FinPadi_TextPrimary)),
              ],
            ),
            const SizedBox(height: 12),

            // Frequency
            _buildInfoRow(Icons.calendar_today, _formatFrequency(frequency)),

            // Next/Last Debit
            if (status == 'active' && nextDebitAt != null)
              _buildInfoRow(Icons.schedule, 'Next debit: ${_formatDate(nextDebitAt)}'),
            
            if (lastDebitAt != null)
              _buildInfoRow(Icons.check_circle_outline, 'Last debit: ${_formatDate(lastDebitAt)}', color: FinPadi_SuccessGreen),

            const SizedBox(height: 12),

            // Action Buttons
            if (status == 'active')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pause(id),
                      child: Text('Pause', style: GoogleFonts.inter(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: FinPadi_NavyBlue),
                        foregroundColor: FinPadi_NavyBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(id),
                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: FinPadi_ErrorRed),
                        foregroundColor: FinPadi_ErrorRed,
                      ),
                    ),
                  ),
                ],
              )
            else if (status == 'paused')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _resume(id),
                      child: Text('Resume', style: GoogleFonts.inter(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinPadi_ActionOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(id),
                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: FinPadi_ErrorRed),
                        foregroundColor: FinPadi_ErrorRed,
                      ),
                    ),
                  ),
                ],
              )
            else if (status == 'created' || status == 'pending')
              Text('Waiting for UPI authorization...', style: GoogleFonts.inter(fontSize: 13, color: FinPadi_ActionOrange, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
      case 'authenticated':
        bgColor = FinPadi_SuccessGreen.withOpacity(0.1);
        textColor = FinPadi_SuccessGreen;
        label = 'ACTIVE';
        break;
      case 'paused':
        bgColor = FinPadi_ActionOrange.withOpacity(0.1);
        textColor = FinPadi_ActionOrange;
        label = 'PAUSED';
        break;
      case 'cancelled':
      case 'failed':
        bgColor = FinPadi_ErrorRed.withOpacity(0.1);
        textColor = FinPadi_ErrorRed;
        label = 'CANCELLED';
        break;
      case 'created':
      case 'pending':
        bgColor = FinPadi_NavyBlue.withOpacity(0.1);
        textColor = FinPadi_NavyBlue;
        label = 'PENDING';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? FinPadi_TextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: color ?? FinPadi_TextSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Auto-debit daily';
      case 'weekly':
        return 'Auto-debit weekly';
      case 'monthly':
        return 'Auto-debit monthly';
      default:
        return 'Auto-debit $frequency';
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}

// Create Mandate Dialog
class CreateMandateDialog extends StatefulWidget {
  const CreateMandateDialog({super.key});

  @override
  State<CreateMandateDialog> createState() => _CreateMandateDialogState();
}

class _CreateMandateDialogState extends State<CreateMandateDialog> {
  String _frequency = 'daily';
  int _maxAmount = 500; // ₹500 default
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enable Auto-Invest', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set up UPI AutoPay to automatically invest your roundups.', style: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextSecondary)),
            const SizedBox(height: 20),

            // Frequency Selector
            Text('Frequency', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Daily', style: GoogleFonts.inter(fontSize: 13)),
                  selected: _frequency == 'daily',
                  onSelected: (val) => setState(() => _frequency = 'daily'),
                  selectedColor: FinPadi_ActionOrange.withOpacity(0.2),
                  labelStyle: TextStyle(color: _frequency == 'daily' ? FinPadi_ActionOrange : FinPadi_TextSecondary),
                ),
                ChoiceChip(
                  label: Text('Weekly', style: GoogleFonts.inter(fontSize: 13)),
                  selected: _frequency == 'weekly',
                  onSelected: (val) => setState(() => _frequency = 'weekly'),
                  selectedColor: FinPadi_ActionOrange.withOpacity(0.2),
                  labelStyle: TextStyle(color: _frequency == 'weekly' ? FinPadi_ActionOrange : FinPadi_TextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Max Amount Slider
            Text('Max Amount per Debit: ₹$_maxAmount', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            Slider(
              value: _maxAmount.toDouble(),
              min: 100,
              max: 5000,
              divisions: 49,
              label: '₹$_maxAmount',
              activeColor: FinPadi_ActionOrange,
              onChanged: (val) => setState(() => _maxAmount = val.toInt()),
            ),
            const SizedBox(height: 16),

            // Terms Checkbox
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
              title: Text('I agree to RBI regulations and authorize auto-debits', style: GoogleFonts.inter(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: FinPadi_ActionOrange,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(color: FinPadi_TextSecondary)),
        ),
        ElevatedButton(
          onPressed: _acceptedTerms ? () => Navigator.of(context).pop({'frequency': _frequency, 'maxAmount': _maxAmount}) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: FinPadi_ActionOrange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          ),
          child: Text('Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
