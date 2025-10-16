import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/customDash.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title: "Good Morning, User",
                  subtitle: "Ready to create amazing woodwork quotation?",
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 35),

                CustomDashboard(
                  dashboardIcons: [
                    DashboardIcon(
                      title: "Create Quotation",
                      icon: Icons.calculate,
                      onTap: () {
                        Nav.push(AllQuotations());
                      },
                    ),
                    DashboardIcon(
                      title: "Add Product",
                      icon: Icons.add_box_outlined,
                      onTap: () {},
                    ),
                    DashboardIcon(
                      title: "Generate Invoice",
                      icon: Icons.receipt_long_outlined,
                      onTap: () {},
                    ),
                    DashboardIcon(
                      title: "View Order",
                      icon: Icons.list_alt_outlined,
                      onTap: () {},
                    ),
                    DashboardIcon(
                      title: "Order",
                      icon: Icons.shopping_cart_outlined,
                      onTap: () {},
                    ),
                    DashboardIcon(
                      title: "Sales",
                      icon: Icons.trending_up_outlined,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                CustomEmptyQuotes(
                  title: "Recent Quotations",
                  buttonText: "View All",
                  emptyMessage: "No Quotations yet",
                  onButtonTap: () {},
                ),

                SizedBox(height: 30),

                CustomEmptyQuotes(
                  title: "Recent Products",
                  buttonText: "View All",
                  emptyMessage: "No recent activity",
                  onButtonTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
