import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/FirstQuote.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';





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
    
    final quotations = await ref.read(quotationSummaryProvider.notifier).getAllQuotations();
    
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
    await ref.read(quotationSummaryProvider.notifier).deleteQuotationById(quotationId);
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

  double _calculateMaterialCost(List<Map<String, dynamic>> materials) {
    return materials.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item["Price"]?.toString() ?? "0") ?? 0.0),
    );
  }

  double _calculateAdditionalCost(List<Map<String, dynamic>> additionalCosts) {
    return additionalCosts.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item["amount"]?.toString() ?? "0") ?? 0.0),
    );
  }

  double _calculateTotalCost(Map<String, dynamic> quotation, int quantity) {
    final materials = List<Map<String, dynamic>>.from(quotation["materials"] ?? []);
    final additionalCosts = List<Map<String, dynamic>>.from(quotation["additionalCosts"] ?? []);
    
    double total = _calculateMaterialCost(materials) + _calculateAdditionalCost(additionalCosts);
    return total * quantity;
  }

  @override
  Widget build(BuildContext context) {
    // 👂 Listen for provider updates
    ref.listen<Map<String, dynamic>>(quotationSummaryProvider, (prev, next) {
      // Reload quotations when provider changes
      _loadAllQuotations();
    });

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
  appBar: AppBar(
    title: Text("Quotations (${allQuotations.length})"),
    backgroundColor: Colors.purple,
  ),
  body: Stack(
    children: [
      // Main List
      SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllQuotations,
          child: ListView.builder(
            padding: const EdgeInsets.only(
                left: 20, right: 20, top: 20, bottom: 140), 
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
                  costPrice: _calculateTotalCost(quotation, currentQuantity),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
  icon: Icons.add,
  onPressed: () {
    // ✅ Pass all quotations with their quantities
    final quotationQuantitiesMap = <String, int>{};
    
    for (int i = 0; i < allQuotations.length; i++) {
      final quotationId = allQuotations[i]["id"] as String;
      quotationQuantitiesMap[quotationId] = quantities[i] ?? 1;
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
                },
              ),
              const SizedBox(height: 10),

              CustomButton(
                text: "Add Item from Quotation",
                icon: Icons.add,
                outlined: true,
                onPressed: () {
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
