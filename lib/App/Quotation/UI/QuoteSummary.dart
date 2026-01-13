import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/UI/FirstQuote.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';



class QuotationSummary extends ConsumerStatefulWidget {
  const QuotationSummary({super.key});

  @override
  ConsumerState<QuotationSummary> createState() => _QuotationSummaryState();
}

class _QuotationSummaryState extends ConsumerState<QuotationSummary> {
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

  // ✅ Calculate total cost with quantity multiplier
  double _calculateTotalCost(Map<String, dynamic> quotation, int quantity) {
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = 0.0;
    int disabledCount = 0;
    for (final material in materials) {
      final price =
          double.tryParse((material["Price"]?.toString() ?? "0")) ?? 0.0;
      final materialQty =
          int.tryParse((material["quantity"]?.toString() ?? "1")) ?? 1;
      final disableIncrement = material["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quantity;
      if (disableIncrement) disabledCount += 1;
      materialTotal += price * materialQty * multiplier;
    }

    double additionalTotal = 0.0;
    for (final cost in additionalCosts) {
      final amount =
          double.tryParse((cost["amount"]?.toString() ?? "0")) ?? 0.0;
      additionalTotal += amount * quantity;
    }

    final total = materialTotal + additionalTotal;
    debugPrint(
      "📊 [QUOTE SUMMARY] qty=$quantity materials=${materials.length} "
      "disabled=$disabledCount materialTotal=${materialTotal.toStringAsFixed(2)} "
      "additionalTotal=${additionalTotal.toStringAsFixed(2)} "
      "total=${total.toStringAsFixed(2)}",
    );
    return total;
  }

  // ✅ Calculate total selling price with quantity multiplier
  double _calculateTotalSellingPrice(Map<String, dynamic> quotation, int quantity) {
    final baseCost = _getCostPrice(quotation);
    final baseSelling = _getSellingPrice(quotation);
    if (baseCost <= 0) return 0.0;
    final totalCost = _calculateTotalCost(quotation, quantity);
    final ratio = baseSelling / baseCost;
    return totalCost * ratio;
  }

  @override
  Widget build(BuildContext context) {
    // 👂 Listen for provider updates
    ref.listen<Map<String, dynamic>>(quotationSummaryProvider, (prev, next) {
      // Reload quotations when provider changes
      _loadAllQuotations();
    });

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (allQuotations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Quotation Summary"),
          backgroundColor: Colors.purple,
        ),
        body: const Center(
          child: Text("No quotations found. Add a product to create one!"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: CustomText(title: "Quotations (${allQuotations.length})"),
      ),
      body: Stack(
        children: [
          // Main List
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAllQuotations,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 200, // Increased to accommodate buttons
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
                      onDelete: () => _deleteQuotation(quotation["id"], index),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom sheet-like container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: "Continue",
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      final quotationQuantitiesMap = <String, int>{};

                      for (int i = 0; i < allQuotations.length; i++) {
                        final quotationId = allQuotations[i]["id"] as String;
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
                  const SizedBox(height: 10),
                  CustomButton(
                    text: "Create new BOM",
                    icon: Icons.add,
                    outlined: true,
                    onPressed: () {
                      Nav.push(AddMaterial());
                    },
                  ),
                  const SizedBox(height: 10),

                  CustomButton(
                    text: "Add Item from Quotation",
                    icon: Icons.add,
                    outlined: true,
                    onPressed: () {
                      Nav.push(AllClientQuotations());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
