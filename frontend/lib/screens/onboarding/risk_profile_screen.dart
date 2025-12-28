import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/screens/auth/register_screen.dart';
import 'package:roundup_app/utils/notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiskProfileScreen extends StatefulWidget {
  const RiskProfileScreen({super.key});

  @override
  State<RiskProfileScreen> createState() => _RiskProfileScreenState();
}

class _RiskProfileScreenState extends State<RiskProfileScreen> {
  String? _selectedTier;
  final bool _loading = false;

  final List<Map<String, dynamic>> _tiers = [
    {
      'value': 'low',
      'title': 'Conservative',
      'subtitle': 'Low Risk',
      'description': '80% Debt Funds, 15% Equity, 5% Gold',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFF8ed16f),
      'returns': '6-8% annually',
    },
    {
      'value': 'medium',
      'title': 'Balanced',
      'subtitle': 'Medium Risk',
      'description': '50% Equity, 40% Debt, 10% Gold',
      'icon': Icons.balance_outlined,
      'color': const Color(0xFFff9a8d),
      'returns': '10-12% annually',
    },
    {
      'value': 'high',
      'title': 'Aggressive',
      'subtitle': 'High Risk',
      'description': '80% Equity, 10% Debt, 10% Gold',
      'icon': Icons.trending_up,
      'color': const Color(0xFF4a536b),
      'returns': '12-15% annually',
    },
  ];

  void _continue() async {
    if (_selectedTier == null) {
      Notifier.error('Please select a risk profile');
      return;
    }

    // Mark onboarding as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    // Navigate to registration
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(initialRiskTier: _selectedTier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Risk Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Select an investment strategy that matches your risk appetite',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF747474),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ..._tiers.map((tier) => _buildTierCard(tier)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can change your risk profile anytime from Settings',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTier != null ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff9a8d),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final isSelected = _selectedTier == tier['value'];

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier['value'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (tier['color'] as Color) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (tier['color'] as Color).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (tier['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tier['icon'] as IconData,
                color: tier['color'] as Color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tier['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF070706),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: tier['color'] as Color,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: tier['color'] as Color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tier['description'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF747474),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expected: ${tier['returns']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
