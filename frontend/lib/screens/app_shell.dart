import 'package:flutter/material.dart';
import 'package:roundup_app/screens/home_screen.dart';
import 'package:roundup_app/screens/roundups_screen.dart';
import 'package:roundup_app/screens/portfolio_screen.dart';
import 'package:roundup_app/screens/settings_screen.dart';
import 'package:roundup_app/screens/ai_advice_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeScreen(),
      RoundupsScreen(),
      PortfolioScreen(),
      SettingsScreen(),
      AiAdviceScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), label: 'Roundups'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: 'AI'),
        ],
      ),
    );
  }
}
