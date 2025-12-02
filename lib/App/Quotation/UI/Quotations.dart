import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/UI/BomList.dart';
import 'package:wworker/App/Quotation/UI/FirstQuote.dart';
import 'package:wworker/App/Quotation/UI/ImportBom.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';



class AllQuotations extends ConsumerStatefulWidget {
  const AllQuotations({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AllQuotationsState();
}

class _AllQuotationsState extends ConsumerState<AllQuotations> {
  List<Map<String, dynamic>> allQuotations = [];
  Map<int, int> quantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllQuotations();
  }

  Future<void> _loadAllQuotations() async {
    setState(() => isLoading = true);

    final quotations = await ref
        .read(quotationSummaryProvider.notifier)
        .getAllQuotations();

    setState(() {
      allQuotations = quotations;
      // Initialize quantities for each quotation
      for (int i = 0; i < quotations.length; i++) {
        quantities[i] = 1;
      }
      isLoading = false;
    });
  }

  void _increaseQuantity(int index) {
    setState(() {
      quantities[index] = (quantities[index] ?? 1) + 1;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if ((quantities[index] ?? 1) > 1) {
        quantities[index] = (quantities[index] ?? 1) - 1;
      }
    });
  }

  Future<void> _deleteQuotation(String quotationId, int index) async {
    await ref
        .read(quotationSummaryProvider.notifier)
        .deleteQuotationById(quotationId);
    await _loadAllQuotations(); // Refresh the list

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Quotation deleted"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Get cost price from quotation (materials + additional costs)
  double _getCostPrice(Map<String, dynamic> quotation) {
    // If costPrice is already calculated and stored
    if (quotation.containsKey("costPrice")) {
      return (quotation["costPrice"] as num?)?.toDouble() ?? 0.0;
    }

    // Otherwise calculate it
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = materials.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item["Price"]?.toString() ?? "0") ?? 0.0),
    );

    double additionalTotal = additionalCosts.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item["amount"]?.toString() ?? "0") ?? 0.0),
    );

    return materialTotal + additionalTotal;
  }

  // ✅ Get selling price from quotation (cost price + overhead)
  double _getSellingPrice(Map<String, dynamic> quotation) {
    // If sellingPrice is already calculated and stored
    if (quotation.containsKey("sellingPrice")) {
      return (quotation["sellingPrice"] as num?)?.toDouble() ?? 0.0;
    }

    // Otherwise return cost price (for backward compatibility)
    return _getCostPrice(quotation);
  }

  // ✅ Calculate total with quantity multiplier
  double _calculateTotalCost(Map<String, dynamic> quotation, int quantity) {
    return _getCostPrice(quotation) * quantity;
  }

  // ✅ Calculate total selling price with quantity multiplier
  double _calculateTotalSellingPrice(
    Map<String, dynamic> quotation,
    int quantity,
  ) {
    return _getSellingPrice(quotation) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for provider updates
    ref.listen<Map<String, dynamic>>(quotationSummaryProvider, (prev, next) {
      _loadAllQuotations();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: CustomText(title: "Quotations"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : allQuotations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: CustomEmptyQuotes(
                          title: "",
                          buttonText: "",
                          emptyMessage: "No Quotations Found",
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllQuotations,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 20,
                        ),
                        itemCount: allQuotations.length,
                        itemBuilder: (context, index) {
                          final quotation = allQuotations[index];
                          final product = quotation["product"] ?? {};
                          final currentQuantity = quantities[index] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: QuoteGlanceCard(
                              imageUrl: product["image"] ?? "",
                              productName: product["name"] ?? "Unknown Product",
                              bomNo: product["productId"] ?? "N/A",
                              description: product["description"] ?? "",
                              costPrice: _calculateTotalCost(
                                quotation,
                                currentQuantity,
                              ),
                              sellingPrice: _calculateTotalSellingPrice(
                                quotation,
                                currentQuantity,
                              ),
                              quantity: currentQuantity,
                              onIncrease: () => _increaseQuantity(index),
                              onDecrease: () => _decreaseQuantity(index),
                              onDelete: () =>
                                  _deleteQuotation(quotation["id"], index),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full width continue button
                    if (allQuotations.isNotEmpty) ...[
                      CustomButton(
                        text: "Continue",
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          final quotationQuantitiesMap = <String, int>{};
                          for (int i = 0; i < allQuotations.length; i++) {
                            final quotationId =
                                allQuotations[i]["id"] as String;
                            quotationQuantitiesMap[quotationId] =
                                quantities[i] ?? 1;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FirstQuote(
                                selectedQuotations: allQuotations,
                                quotationQuantities: quotationQuantitiesMap,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    /// 3 buttons in a single row
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            textSize: 15,
                            text: "Create",
                            outlined: allQuotations.isNotEmpty,
                            icon: Icons.add,
                            onPressed: () {
                              Nav.push(AddMaterial());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            textSize: 15,
                            text: "BOM",
                            outlined: true,
                            onPressed: () {
                              //  Nav.push(BOMList());
                              Nav.push(ImportQuotationsPage());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            textSize: 15,
                            text: "Import",
                            outlined: true,
                            onPressed: () {
                              Nav.push(AllClientQuotations());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
