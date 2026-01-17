import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Dashboad/Widget/itemCard.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/AddMaterial.dart';
import 'package:wworker/App/Quotation/UI/FirstQuote.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/UI/BomSummary.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';
import 'package:intl/intl.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/App/OverHead/Widget/OCCalculator.dart';
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
  final BOMService _bomService = BOMService();
  List<Map<String, dynamic>> allQuotations = [];
  Map<int, int> quantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllQuotations();
  }

  Future<List<_BomImportItem>> _fetchBoms() async {
    final response = await _bomService.getAllBOMs();
    if (response["success"] == true) {
      final data = response["data"] as List<dynamic>? ?? [];
      return data
          .map((item) => _BomImportItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> _importBom(BuildContext context, _BomImportItem bom) async {
    final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
    final newQuotation = {
      "product": bom.product,
      "materials": bom.materials,
      "additionalCosts": bom.additionalCosts,
      "costPrice": bom.pricing.costPrice,
      "sellingPrice": bom.pricing.sellingPrice,
      "overheadCost": bom.pricing.overheadCost,
      "markupPercentage": bom.pricing.markupPercentage,
      "pricingMethod": bom.pricing.pricingMethod,
      "expectedDuration": bom.expectedDurationValue,
      "expectedPeriod": bom.expectedDurationUnit,
      "importedFromBom": bom.id,
    };

    await quotationNotifier.addNewQuotation(newQuotation);
    await _loadAllQuotations();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ BOM imported to quotations"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editBomBeforeImport(BuildContext context, _BomImportItem bom) async {
    final materialNotifier = ref.read(materialProvider.notifier);
    final quotationNotifier = ref.read(quotationSummaryProvider.notifier);

    await materialNotifier.clearAll();
    for (final item in bom.materials) {
      await materialNotifier.addMaterial(item);
    }
    for (final cost in bom.additionalCosts) {
      await materialNotifier.addAdditionalCost(cost);
    }

    await quotationNotifier.setProduct(bom.product);
    await PricingSettingsManager.saveMarkup(bom.pricing.markupPercentage);
    await PricingSettingsManager.savePricingMethod(bom.pricing.pricingMethod);

    if (mounted) {
      Navigator.pop(context);
      Nav.push(const BOMSummary());
    }
  }

  void _showImportBomsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.98,
          minChildSize: 0.8,
          maxChildSize: 0.98,
          expand: true,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: FutureBuilder<List<_BomImportItem>>(
                future: _fetchBoms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final boms = snapshot.data ?? [];
                  if (boms.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          "No BOMs available to import",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  return SafeArea(
                    top: false,
                    child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Import BOMs",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF302E2E),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: boms.length,
                          itemBuilder: (context, index) {
                            final bom = boms[index];
                            return _ImportBomDetailsCard(
                              bom: bom,
                              onImport: () => _importBom(context, bom),
                              onEdit: () => _editBomBeforeImport(context, bom),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  );
                },
              ),
            );
          },
        );
      },
    );
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
            title: "Import BOMs",
            message:
                "Import BOMs to turn them into quotations. Review existing quotations "
                "here, adjust quantities, and confirm pricing with the client. Once "
                "approved, you can proceed to Orders or Invoices.",
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

                    /// Buttons row
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
                        // const SizedBox(width: 12),
                        // Expanded(
                        //   child: CustomButton(
                        //     textSize: 15,
                        //     text: "BOM",
                        //     outlined: true,
                        //     onPressed: () {
                        //       // Nav.push(ImportQuotationsPage());
                        //     },
                        //   ),
                        // ),
                        const SizedBox(width: 12),

                    Expanded(child:  CustomButton(
                      text: "Import BOM",
                      outlined: true,
                      onPressed: _showImportBomsSheet,
                    ),)

                        
                        // Expanded(
                        //   child: CustomButton(
                        //     textSize: 15,
                        //     text: "Import",
                        //     outlined: true,
                        //     onPressed: () {
                        //       // Nav.push(const AllClientQuotations(
                        //       //   isImportMode: true,
                        //       // ));
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                    //const SizedBox(height: 12),
 
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

class _BomImportItem {
  final String id;
  final String bomNumber;
  final String name;
  final String description;
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> additionalCosts;
  final _BomPricing pricing;
  final int? expectedDurationValue;
  final String? expectedDurationUnit;

  _BomImportItem({
    required this.id,
    required this.bomNumber,
    required this.name,
    required this.description,
    required this.product,
    required this.materials,
    required this.additionalCosts,
    required this.pricing,
    required this.expectedDurationValue,
    required this.expectedDurationUnit,
  });

  factory _BomImportItem.fromJson(Map<String, dynamic> json) {
    final product = Map<String, dynamic>.from(json["product"] ?? {});
    final materials = (json["materials"] as List<dynamic>? ?? [])
        .map((item) => _mapMaterial(item as Map<String, dynamic>))
        .toList();
    final additionalCosts = (json["additionalCosts"] as List<dynamic>? ?? [])
        .map((item) => _mapCost(item as Map<String, dynamic>))
        .toList();
    final expectedDuration = json["expectedDuration"] as Map<String, dynamic>?;

    return _BomImportItem(
      id: json["_id"] ?? "",
      bomNumber: json["bomNumber"] ?? "BOM",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      product: {
        "productId": product["productId"] ?? "",
        "name": product["name"] ?? "",
        "description": product["description"] ?? "",
        "image": product["image"] ?? "",
      },
      materials: materials,
      additionalCosts: additionalCosts,
      pricing: _BomPricing.fromJson(json["pricing"] as Map<String, dynamic>?),
      expectedDurationValue: expectedDuration?["value"],
      expectedDurationUnit: expectedDuration?["unit"],
    );
  }

  static Map<String, dynamic> _mapMaterial(Map<String, dynamic> item) {
    return {
      "Product": item["type"] ?? item["name"] ?? "Material",
      "Materialname": item["description"] ?? item["name"] ?? "Imported Item",
      "Width": item["width"]?.toString() ?? "",
      "Length": item["length"]?.toString() ?? "",
      "Thickness": item["thickness"]?.toString() ?? "",
      "Unit": item["unit"] ?? "",
      "Sqm": item["squareMeter"]?.toString() ?? "",
      "Price": item["price"]?.toString() ?? "",
      "quantity": item["quantity"]?.toString() ?? "1",
    };
  }

  static Map<String, dynamic> _mapCost(Map<String, dynamic> item) {
    return {
      "type": item["name"] ?? "",
      "description": item["description"] ?? "",
      "amount": item["amount"]?.toString() ?? "0",
    };
  }
}

class _BomPricing {
  final String pricingMethod;
  final double markupPercentage;
  final double materialsTotal;
  final double additionalTotal;
  final double overheadCost;
  final double costPrice;
  final double sellingPrice;

  _BomPricing({
    required this.pricingMethod,
    required this.markupPercentage,
    required this.materialsTotal,
    required this.additionalTotal,
    required this.overheadCost,
    required this.costPrice,
    required this.sellingPrice,
  });

  factory _BomPricing.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return _BomPricing(
        pricingMethod: "Method 1",
        markupPercentage: 0,
        materialsTotal: 0,
        additionalTotal: 0,
        overheadCost: 0,
        costPrice: 0,
        sellingPrice: 0,
      );
    }
    return _BomPricing(
      pricingMethod: json["pricingMethod"] ?? "Method 1",
      markupPercentage: (json["markupPercentage"] ?? 0).toDouble(),
      materialsTotal: (json["materialsTotal"] ?? 0).toDouble(),
      additionalTotal: (json["additionalTotal"] ?? 0).toDouble(),
      overheadCost: (json["overheadCost"] ?? 0).toDouble(),
      costPrice: (json["costPrice"] ?? 0).toDouble(),
      sellingPrice: (json["sellingPrice"] ?? 0).toDouble(),
    );
  }
}

class _ImportBomCard extends StatelessWidget {
  final _BomImportItem bom;
  final VoidCallback onImport;
  final VoidCallback onEdit;

  const _ImportBomCard({
    required this.bom,
    required this.onImport,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = bom.product["image"]?.toString() ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade500,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bom.name.isEmpty ? bom.bomNumber : bom.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bom.bomNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₦${bom.pricing.sellingPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA16438),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Edit",
                  outlined: true,
                  height: 44,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "Import",
                  height: 44,
                  onPressed: onImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportBomDetailsCard extends StatelessWidget {
  final _BomImportItem bom;
  final VoidCallback onImport;
  final VoidCallback onEdit;

  const _ImportBomDetailsCard({
    required this.bom,
    required this.onImport,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = bom.product["image"]?.toString() ?? "";
    final formatter = NumberFormat.decimalPattern();
    final costLabel = formatter.format(bom.pricing.costPrice.round());
    final sellingLabel = formatter.format(bom.pricing.sellingPrice.round());
    final overheadLabel = formatter.format(bom.pricing.overheadCost.round());
    final materialsCount = bom.materials.length;
    final additionalCount = bom.additionalCosts.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey.shade500,
                      size: 40,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bom.name.isEmpty ? bom.bomNumber : bom.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF302E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bom.bomNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bom.description.isEmpty ? "No description" : bom.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Items • $materialsCount materials",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "Costs • $additionalCount",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Cost Price",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "₦$costLabel",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Overhead Cost",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "₦$overheadLabel",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA16438)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Selling Price",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF302E2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₦$sellingLabel",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA16438),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Edit",
                        outlined: true,
                        textColor: ColorsApp.btnColor,
                        borderColor: ColorsApp.btnColor,
                        height: 52,
                        textSize: 18,
                        padding: 8,
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: "Import",
                        height: 52,
                        textSize: 18,
                        padding: 8,
                        backgroundColor: ColorsApp.btnColor,
                        textColor: Colors.white,
                        onPressed: onImport,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
