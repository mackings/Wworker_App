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
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double total =
        _calculateMaterialCost(materials) +
        _calculateAdditionalCost(additionalCosts);
    return total * quantity;
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
                        padding: EdgeInsets.only(left: 20,right: 20),
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
      mainAxisSize: MainAxisSize.min, // Add this
      children: [
        // Full width continue button
        if (allQuotations.isNotEmpty) ...[
          CustomButton(
            text: "Continue",
            icon: Icons.arrow_forward,
            onPressed: () {
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
                text: "View BOMs",
                outlined: true,
               // icon: Icons.add,
                onPressed: () {
                  Nav.push(BOMList());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                textSize: 15,
                text: "Quotation",
                outlined: true,
                //icon: Icons.add,
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
)



          ],
        ),
      ),
    );
  }
}
