import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/customDash.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Providers/QuotationProvider.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/App/Quotation/UI/QuoteSummary.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/Constant/urls.dart';
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
    final quotationsState = ref.watch(quotationProvider);
    final notifier = ref.read(quotationProvider.notifier);

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
                  title: "Good Evening",
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
                      onTap: () {
                        Nav.push(AddProduct());
                      },
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

                // ✅ Recent Quotations Section
                quotationsState.when(
                  data: (quotations) {
                    if (quotations.isEmpty) {
                      return CustomEmptyQuotes(
                        title: "Recent Quotations",
                        buttonText: "View All",
                        emptyMessage: "No Quotations yet",
                        onButtonTap: () {
                          Nav.push(AllQuotations());
                        },
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          title: "Recent Quotations",
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quotations.length,
                          itemBuilder: (context, index) {
                            final quotation = quotations[index];
                            final firstItem = quotation.items.isNotEmpty
                                ? quotation.items.first
                                : null;

                            return ClientQuotationCard(
                              quotation: {
                                'clientName': quotation.clientName,
                                'phoneNumber': quotation.phoneNumber,
                                'description': quotation.description,
                                'finalTotal': quotation.finalTotal,
                                'status': quotation.status,
                                'createdAt': quotation.createdAt
                                    .toIso8601String(),
                                'quotationNumber': quotation.quotationNumber,
                                'items': firstItem != null
                                    ? [
                                        {
                                          'productName':
                                              quotation.service.product,
                                          'woodType':
                                              firstItem.woodType ?? 'N/A',
                                          'image': firstItem.image.isNotEmpty
                                              ? firstItem.image
                                              : Urls.woodImg,
                                        },
                                      ]
                                    : [],
                              },
                              onDelete: () =>
                                  notifier.deleteQuotation(quotation.id),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text("Failed to load quotations: $error")),
                ),

                const SizedBox(height: 30),

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
