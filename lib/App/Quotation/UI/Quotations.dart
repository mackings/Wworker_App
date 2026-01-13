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
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';



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
    _logQuantityChange(index);
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if ((quantities[index] ?? 1) > 1) {
        quantities[index] = (quantities[index] ?? 1) - 1;
      }
    });
    _logQuantityChange(index);
  }

  void _logQuantityChange(int index) {
    if (index < 0 || index >= allQuotations.length) return;
    final quotation = allQuotations[index];
    final quantity = quantities[index] ?? 1;
    final costPrice = _getCostPrice(quotation);
    final sellingPrice = _getSellingPrice(quotation);
    final totalCost = _calculateTotalCost(quotation, quantity);
    final totalSelling = _calculateTotalSellingPrice(quotation, quantity);

    debugPrint(
      "📊 [QUOTE QTY] index=$index qty=$quantity "
      "costUnit=${costPrice.toStringAsFixed(2)} "
      "sellUnit=${sellingPrice.toStringAsFixed(2)} "
      "costTotal=${totalCost.toStringAsFixed(2)} "
      "sellTotal=${totalSelling.toStringAsFixed(2)}",
    );
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
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = 0.0;
    for (final material in materials) {
      final price =
          double.tryParse((material["Price"] ?? "0").toString()) ?? 0.0;
      final materialQty =
          int.tryParse((material["quantity"] ?? "1").toString()) ?? 1;
      final disableIncrement = material["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quantity;
      materialTotal += price * materialQty * multiplier;
    }

    double additionalTotal = 0.0;
    for (final cost in additionalCosts) {
      final amount =
          double.tryParse((cost["amount"] ?? "0").toString()) ?? 0.0;
      additionalTotal += amount * quantity;
    }

    return materialTotal + additionalTotal;
  }

  // ✅ Calculate total selling price with quantity multiplier
  double _calculateTotalSellingPrice(
    Map<String, dynamic> quotation,
    int quantity,
  ) {
    final baseCost = _getCostPrice(quotation);
    final baseSelling = _getSellingPrice(quotation);
    if (baseCost <= 0) return 0.0;
    final totalCost = _calculateTotalCost(quotation, quantity);
    final ratio = baseSelling / baseCost;
    return totalCost * ratio;
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
        actions: const [
          GuideHelpIcon(
            title: "Quotations",
            message:
                "Quotations are created from your BOMs and used to agree on price "
                "before work starts. Review each quote, adjust quantity, and confirm "
                "pricing with the client. Once approved, you can create an Order to "
                "track production and payments, or create an Invoice to request payment. "
                "Materials marked 'disable increment' keep a fixed price when quantity changes.",
          ),
        ],
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
