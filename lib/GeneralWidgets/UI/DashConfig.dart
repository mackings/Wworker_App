import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wworker/App/Dashboad/Home.dart';
import 'package:wworker/App/Order/View/allOrders.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/App/Sales/Views/salesHome.dart';
import 'package:wworker/App/Staffing/View/settings.dart';
import 'package:wworker/GeneralWidgets/UI/NavBar.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    Home(),
    AllQuotations(),
    AllOrdersPage(),
    SalesPage(),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Future<bool> _onBackPressed() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Color(0xFFB7835E)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Leave App?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to close wworker?',
          style: TextStyle(height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Stay',
                  onPressed: () => Navigator.pop(context, false),
                  outlined: true,
                  icon: Icons.keyboard_backspace_rounded,
                  height: 50,
                  padding: 12,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Exit',
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icons.close_rounded,
                  height: 50,
                  padding: 12,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onBackPressed();
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(child: _pages[_selectedIndex]),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            BottomNavItem(icon: Icons.home, label: "Home"),
            BottomNavItem(icon: Icons.calculate, label: "Quotation"),
            BottomNavItem(icon: Icons.shopping_cart_outlined, label: "Orders"),
            BottomNavItem(icon: Icons.analytics, label: "Sales"),
            BottomNavItem(icon: Icons.settings, label: "Settings"),
          ],
        ),
      ),
    );
  }
}
