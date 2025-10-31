import 'package:flutter/material.dart';
import 'package:wworker/App/Dashboad/Home.dart';
import 'package:wworker/App/Staffing/View/settings.dart';
import 'package:wworker/GeneralWidgets/UI/NavBar.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Home(),
    Center(child: Text('Orders')),
    Center(child: Text('Quotations')),
    Center(child: Text('Profile')),
    Settings()
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [

          BottomNavItem(icon: Icons.home, label: "Home"),
          BottomNavItem(icon: Icons.calculate, label: "Quotation"),
          BottomNavItem(icon: Icons.shopping_cart_outlined, label: "Orders"),
          BottomNavItem(icon: Icons.description_outlined, label: "Quotes"),
          BottomNavItem(icon: Icons.settings, label: "Settings"),
          
        ],
      ),
    );
  }
}
