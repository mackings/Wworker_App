import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/OverHead/Api/OCService.dart';
import 'package:wworker/App/OverHead/Widget/OCCalculator.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

// ==============================
// UPDATED BOM SUMMARY - WITH PROPER OVERHEAD CALCULATION
// ==============================

class BOMSummary extends ConsumerStatefulWidget {
  const BOMSummary({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BOMSummaryState();
}

class _BOMSummaryState extends ConsumerState<BOMSummary> {
  final BOMService _bomService = BOMService();
  final OverheadCostService _overheadService = OverheadCostService();
  bool isLoading = false;
  bool isSavingBom = false;

  // Overhead Cost State
  List<Map<String, dynamic>> overheadCosts = [];
  bool isLoadingOverhead = true;

  // Expected Duration State
  String? selectedDuration = '1';
  String selectedPeriod = 'Day';
  final List<String> periodOptions = ['Hour', 'Day', 'Week', 'Month'];

  // Pricing Settings (loaded from PricingSettingsManager)
  double markupPercentage = 30.0;
  String pricingMethod = 'Method 1';
  int workingDaysPerMonth = 26;

  @override
  void initState() {
    super.initState();
    _loadOverheadCosts();
    _loadPricingSettings();
  }

  // Load pricing settings from SharedPreferences
  Future<void> _loadPricingSettings() async {
    final markup = await PricingSettingsManager.getMarkup();
    final method = await PricingSettingsManager.getPricingMethod();
    final workingDays = await PricingSettingsManager.getWorkingDays();

    setState(() {
      markupPercentage = markup;
      pricingMethod = method;
      workingDaysPerMonth = workingDays;
    });

    debugPrint("📊 Loaded pricing settings:");
    debugPrint("   Markup: $markupPercentage%");
    debugPrint("   Method: $pricingMethod");
    debugPrint("   Working Days/Month: $workingDaysPerMonth");
  }

  Future<void> _showPricingSettingsDialog() async {
    final markupController = TextEditingController(
      text: markupPercentage.toString(),
    );
    final workingDaysController = TextEditingController(
      text: workingDaysPerMonth.toString(),
    );
    String tempMethod = pricingMethod;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) => SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pricing Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose the pricing method and markup used to calculate selling price.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pricing Method',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B7B7B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMethodCard(
                        title: 'Method 1 — Direct Markup',
                        description:
                            'Best for fast quotes. Overhead is not added to cost price; '
                            'you only apply markup on materials and additional costs.',
                        selected: tempMethod == 'Method 1',
                        onTap: () =>
                            setDialogState(() => tempMethod = 'Method 1'),
                      ),
                      const SizedBox(height: 10),
                      _buildMethodCard(
                        title: 'Method 2 — With Overhead',
                        description:
                            'Best for detailed costing. Manufacturing overhead is added '
                            'to cost price, then markup is applied to the full total.',
                        selected: tempMethod == 'Method 2',
                        onTap: () =>
                            setDialogState(() => tempMethod = 'Method 2'),
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Markup Percentage',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B7B7B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: markupController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: '%',
                          hintText: '30',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Factory Working Days per Month',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B7B7B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: workingDaysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: 'days',
                          hintText: '26',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFA16438),
                                side: const BorderSide(
                                  color: Color(0xFFA16438),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final markup =
                                    double.tryParse(markupController.text) ??
                                    30.0;
                                final workingDays =
                                    int.tryParse(workingDaysController.text) ??
                                    26;

                                if (markup <= 0 || markup > 1000) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid markup percentage (1-1000)',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                if (workingDays <= 0 || workingDays > 31) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter valid working days (1-31)',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                await PricingSettingsManager.saveMarkup(markup);
                                await PricingSettingsManager.savePricingMethod(
                                  tempMethod,
                                );
                                await PricingSettingsManager.saveWorkingDays(
                                  workingDays,
                                );

                                setState(() {
                                  markupPercentage = markup;
                                  pricingMethod = tempMethod;
                                  workingDaysPerMonth = workingDays;
                                });

                                if (context.mounted) Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA16438),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Settings',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E0) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFA16438) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? const Color(0xFFA16438) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Duration options
  List<String> get durationOptions {
    switch (selectedPeriod) {
      case 'Hour':
        return List.generate(24 * 30, (index) => '${index + 1}');
      case 'Day':
        return List.generate(365, (index) => '${index + 1}');
      case 'Week':
        return List.generate(52, (index) => '${index + 1}');
      case 'Month':
        return List.generate(12, (index) => '${index + 1}');
      default:
        return List.generate(365, (index) => '${index + 1}');
    }
  }

  // Load Overhead Costs from API
  Future<void> _loadOverheadCosts() async {
    setState(() => isLoadingOverhead = true);

    try {
      var costs = await OverheadCostManager.getOverheadCosts();
      debugPrint("📊 Loaded ${costs.length} cached overhead costs");

      if (costs.isEmpty) {
        final serverCosts = await _overheadService.getOverheadCosts();
        costs = serverCosts
            .map(
              (cost) => {
                "_id": cost.id,
                "id": cost.id,
                "category": cost.category,
                "description": cost.description,
                "period": cost.period,
                "cost": cost.cost,
                "user": cost.user,
                "createdAt": cost.createdAt.toIso8601String(),
              },
            )
            .toList();
        debugPrint("📊 Loaded ${costs.length} server overhead costs");
      }

      setState(() {
        overheadCosts = costs;
        isLoadingOverhead = false;
      });

      debugPrint("📊 BOM Summary using ${costs.length} overhead costs");
    } catch (e) {
      debugPrint("⚠️ Error loading overhead costs: $e");
      setState(() {
        overheadCosts = [];
        isLoadingOverhead = false;
      });
    }
  }

  // Uses the same overhead calculator as the Overhead/Profile page, then
  // applies it to this BOM's selected duration.
  double calculateManufacturingOverhead() {
    if (overheadCosts.isEmpty || selectedDuration == null) {
      debugPrint("💰 No overhead costs or duration not selected");
      return 0.0;
    }

    final int duration = int.tryParse(selectedDuration!) ?? 0;
    if (duration == 0) {
      debugPrint("💰 Duration is 0");
      return 0.0;
    }

    try {
      debugPrint("💰 ============================================");
      debugPrint("💰 RAW OVERHEAD COSTS DATA:");
      debugPrint("💰 Number of costs: ${overheadCosts.length}");
      for (var cost in overheadCosts) {
        debugPrint(
          "💰   ${cost['description']}: ₦${cost['cost']}/${cost['period']}",
        );
      }
      debugPrint("💰 ============================================");

      final items = overheadCosts.map((cost) {
        final adapter = _CostItemAdapter(
          cost: _toDouble(cost['cost']) ?? 0,
          period: (cost['period'] ?? 'Monthly').toString(),
          category: (cost['category'] ?? '').toString(),
          description: (cost['description'] ?? '').toString(),
        );
        debugPrint(
          "💰 Created adapter: ${adapter.description} - ₦${adapter.cost}/${adapter.period}",
        );
        return adapter;
      }).toList();

      final targetPeriod = selectedPeriod;

      debugPrint("💰 ");
      debugPrint("💰 TARGET PERIOD: $targetPeriod");
      debugPrint("💰 DURATION: $duration $targetPeriod(s)");
      debugPrint("💰 ");

      double overheadPerPeriod =
          OverheadCostCalculator.calculateTotalForDuration(items, targetPeriod);

      debugPrint(
        "💰 Calculated overhead per $targetPeriod: ₦${overheadPerPeriod.toStringAsFixed(2)}",
      );

      // STEP 2: Multiply by the number of periods selected
      final totalOverhead = overheadPerPeriod * duration;

      // Detailed logging for debugging
      debugPrint("💰 ");
      debugPrint("💰 BREAKDOWN PER ITEM:");
      for (var item in items) {
        final convertedCost = OverheadCostCalculator.convertCostToDuration(
          item.cost,
          item.period,
          targetPeriod,
        );
        debugPrint(
          "💰   ${item.description}: ₦${item.cost}/${item.period} → ₦${convertedCost.toStringAsFixed(2)}/$targetPeriod",
        );
      }
      debugPrint("💰 ");
      debugPrint("💰 CALCULATION:");
      debugPrint(
        "💰   Total Overhead per $targetPeriod: ₦${overheadPerPeriod.toStringAsFixed(2)}",
      );
      debugPrint("💰   × Duration: $duration $selectedPeriod(s)");
      debugPrint(
        "💰   = TOTAL MANUFACTURING OVERHEAD: ₦${totalOverhead.toStringAsFixed(2)}",
      );
      debugPrint("💰 ============================================");

      return totalOverhead;
    } catch (e, stackTrace) {
      debugPrint("⚠️ Error calculating overhead: $e");
      debugPrint("⚠️ Stack trace: $stackTrace");
      return 0.0;
    }
  }

  String _bomDurationLabel() {
    final value = int.tryParse(selectedDuration ?? '') ?? 0;
    if (value <= 0) return selectedPeriod;
    final suffix = value == 1 ? '' : 's';
    return "$value ${selectedPeriod.toLowerCase()}$suffix";
  }

  // 📊 Calculate Pricing based on selected method
  Map<String, double> calculatePricing(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    // Calculate material total
    double materialTotal = 0;
    for (var m in materials) {
      materialTotal += _materialLineTotal(m);
    }

    // Calculate additional costs total
    double additionalTotal = 0;
    for (var c in additionalCosts) {
      final amount = double.tryParse(c["amount"].toString()) ?? 0;
      additionalTotal += amount;
    }

    double costPrice = 0;
    double overheadCost = 0;
    double sellingPrice = 0;

    if (pricingMethod == 'Method 1') {
      // METHOD 1: Direct Markup (No MOC in cost price)
      costPrice = materialTotal + additionalTotal;
      overheadCost = 0; // MOC not included in Method 1

      // Add markup to get selling price
      sellingPrice = costPrice * (1 + (markupPercentage / 100));

      debugPrint("💵 METHOD 1 (Direct Markup):");
      debugPrint("   Materials: ₦${materialTotal.toStringAsFixed(2)}");
      debugPrint("   Additional Costs: ₦${additionalTotal.toStringAsFixed(2)}");
      debugPrint("   Cost Price: ₦${costPrice.toStringAsFixed(2)}");
      debugPrint("   Markup: $markupPercentage%");
      debugPrint("   Selling Price: ₦${sellingPrice.toStringAsFixed(2)}");
    } else {
      // METHOD 2: Include Manufacturing Overhead in Cost Price
      overheadCost = calculateManufacturingOverhead();
      costPrice = materialTotal + additionalTotal + overheadCost;

      // Add markup to get selling price
      sellingPrice = costPrice * (1 + (markupPercentage / 100));

      debugPrint("💵 METHOD 2 (With MOC):");
      debugPrint("   Materials: ₦${materialTotal.toStringAsFixed(2)}");
      debugPrint("   Additional Costs: ₦${additionalTotal.toStringAsFixed(2)}");
      debugPrint(
        "   Manufacturing Overhead: ₦${overheadCost.toStringAsFixed(2)}",
      );
      debugPrint("   Cost Price: ₦${costPrice.toStringAsFixed(2)}");
      debugPrint("   Markup: $markupPercentage%");
      debugPrint("   Selling Price: ₦${sellingPrice.toStringAsFixed(2)}");
    }

    return {
      'materialTotal': materialTotal,
      'additionalTotal': additionalTotal,
      'costPrice': costPrice,
      'overheadCost': overheadCost,
      'markupAmount': sellingPrice - costPrice,
      'sellingPrice': sellingPrice,
    };
  }

  // Create Quotation and Continue
  Future<void> _createQuotationAndContinue(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) async {
    try {
      final pricing = calculatePricing(materials, additionalCosts);

      final quotationState = ref.read(quotationSummaryProvider);
      final productData = quotationState["product"];

      if (productData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Product data not found."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final quotationNotifier = ref.read(quotationSummaryProvider.notifier);

      final newQuotation = {
        "product": productData,
        "materials": materials,
        "additionalCosts": additionalCosts,
        "costPrice": pricing['costPrice'],
        "overheadCost": pricing['overheadCost'],
        "sellingPrice": pricing['sellingPrice'],
        "markupPercentage": markupPercentage,
        "pricingMethod": pricingMethod,
        "expectedDuration": selectedDuration,
        "expectedPeriod": selectedPeriod,
      };

      await quotationNotifier.addNewQuotation(newQuotation);
      await ref.read(materialProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("BOM created successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Nav.offAll(const DashboardScreen(initialIndex: 1));
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error creating quotation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double _materialLineTotal(Map<String, dynamic> item) {
    final calculation = item["calculation"];
    if (calculation is Map) {
      final total = _toDouble(calculation["totalMaterialCost"]);
      if (total != null) return total;
    }

    final lineTotal = _toDouble(item["LineTotal"] ?? item["subtotal"]);
    if (lineTotal != null) return lineTotal;

    final price = _toDouble(item["Price"]) ?? 0;
    final qty = _toInt(item["quantity"]) ?? 1;
    return price * qty;
  }

  // ignore: unused_element
  Future<void> _saveBom(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) async {
    if (isSavingBom) return;

    final pricing = calculatePricing(materials, additionalCosts);
    final quotationState = ref.read(quotationSummaryProvider);
    final productData = quotationState["product"] as Map<String, dynamic>?;

    if (productData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Product data not found."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final productId =
        productData["id"] ?? productData["_id"] ?? productData["productId"];

    if (productId == null || productId.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Product ID not found."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final mappedMaterials = materials.map((item) {
      final lineTotal = _materialLineTotal(item);
      final qty = _toInt(item["quantity"]) ?? 1;
      final calculation = item["calculation"] is Map
          ? Map<String, dynamic>.from(item["calculation"] as Map)
          : <String, dynamic>{};
      calculation["totalMaterialCost"] = lineTotal;
      return {
        if (item["materialId"] != null) "materialId": item["materialId"],
        "name": item["Materialname"] ?? item["Product"] ?? "Material",
        "type": item["Product"] ?? item["Materialname"] ?? "",
        if (item["category"] != null) "category": item["category"],
        if (item["subCategory"] != null) "subCategory": item["subCategory"],
        if (item["billingMode"] != null) "billingMode": item["billingMode"],
        "width": _toDouble(item["Width"]),
        "length": _toDouble(item["Length"]),
        "thickness": _toDouble(item["Thickness"]),
        "unit": item["materialUnit"] ?? item["Unit"],
        "squareMeter": _toDouble(item["Sqm"]),
        "price": _toDouble(item["unitPrice"]) ?? lineTotal,
        "quantity": qty,
        "description": item["description"] ?? item["Materialname"] ?? "",
        "calculation": calculation,
        "subtotal": lineTotal,
      };
    }).toList();

    final mappedCosts = additionalCosts.map((cost) {
      return {
        "name": cost["name"] ?? cost["type"] ?? "",
        "amount": _toDouble(cost["amount"]) ?? 0,
        "description": cost["description"] ?? "",
      };
    }).toList();

    final pricingPayload = {
      "pricingMethod": pricingMethod,
      "markupPercentage": markupPercentage,
      "materialsTotal": pricing["materialTotal"] ?? 0,
      "additionalTotal": pricing["additionalTotal"] ?? 0,
      "overheadCost": pricing["overheadCost"] ?? 0,
      "costPrice": pricing["costPrice"] ?? 0,
      "sellingPrice": pricing["sellingPrice"] ?? 0,
    };

    final expectedDuration = selectedDuration == null
        ? null
        : {
            "value": int.tryParse(selectedDuration!) ?? 1,
            "unit": selectedPeriod,
          };

    setState(() => isSavingBom = true);

    final response = await _bomService.createBOM(
      product: {
        "productId": productId.toString(),
        "name": productData["name"] ?? "Product",
        "description": productData["description"] ?? "",
        "image": productData["image"] ?? "",
      },
      name: productData["name"] ?? "BOM",
      description: productData["description"] ?? "",
      materials: mappedMaterials,
      additionalCosts: mappedCosts,
      pricing: pricingPayload,
      expectedDuration: expectedDuration,
    );

    if (!mounted) return;
    setState(() => isSavingBom = false);

    if (response["success"] == true) {
      await ref.read(materialProvider.notifier).clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ BOM saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "❌ Failed to save BOM"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialData = ref.watch(materialProvider);
    final materials = List<Map<String, dynamic>>.from(
      materialData["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      materialData["additionalCosts"] ?? [],
    );

    final pricing = calculatePricing(materials, additionalCosts);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F3),
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _showPricingSettingsDialog,
            icon: const Icon(Icons.tune),
            tooltip: "Pricing Settings",
          ),
          const GuideHelpIcon(
            title: "BOM Summary",
            message:
                "Review your BOM totals here before saving. This page combines "
                "materials, additional costs, and overhead settings to calculate "
                "final pricing. Adjust values until the totals look correct, then "
                "save to create a quotation-ready BOM.",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHero(pricing),
              const SizedBox(height: 18),

              _buildSectionTitle(
                icon: Icons.layers_outlined,
                title: "Materials",
                count: materials.length,
              ),
              const SizedBox(height: 10),

              if (materials.isEmpty)
                _buildEmptyState("No materials added yet.")
              else
                ...materials.map((m) => _buildMaterialCard(m)),

              const SizedBox(height: 22),

              _buildSectionTitle(
                icon: Icons.payments_outlined,
                title: "Additional Costs",
                count: additionalCosts.length,
              ),
              const SizedBox(height: 10),

              if (additionalCosts.isEmpty)
                _buildEmptyState("No additional costs added yet.")
              else
                ...additionalCosts.map((c) => _buildAdditionalCostCard(c)),

              const SizedBox(height: 24),

              // Expected Duration Section (only show for Method 2)
              if (pricingMethod == 'Method 2') ...[
                _buildExpectedDurationSection(),
                const SizedBox(height: 30),
              ],

              // Cost Breakdown Section
              _buildCostBreakdownSection(pricing),

              const SizedBox(height: 24),

              // CustomButton(
              //   text: "Save BOM",
              //   loading: isSavingBom,
              //   outlined: true,
              //   onPressed: isSavingBom
              //       ? null
              //       : () => _saveBom(materials, additionalCosts),
              // ),

              // const SizedBox(height: 12),
              CustomButton(
                text: "Continue",
                onPressed: () =>
                    _createQuotationAndContinue(materials, additionalCosts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHero(Map<String, double> pricing) {
    final formatter = NumberFormat.decimalPattern();
    final selling = formatter.format((pricing['sellingPrice'] ?? 0).round());
    final cost = formatter.format((pricing['costPrice'] ?? 0).round());
    final markupAmount = formatter.format(
      (pricing['markupAmount'] ?? 0).round(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D241E),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOM Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "$pricingMethod • ${markupPercentage.toStringAsFixed(1)}% markup",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(label: 'Cost', value: '₦$cost'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(label: 'Selling', value: '₦$selling'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: 'Markup Profit',
                  value: '₦$markupAmount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF8B4513)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF211D1A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE8DED6)),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF756A61)),
      ),
    );
  }

  Widget _buildExpectedDurationSection() {
    final durationValue =
        selectedDuration != null && durationOptions.contains(selectedDuration)
        ? selectedDuration!
        : durationOptions.first;
    final overheadPreview = calculateManufacturingOverhead();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Expected Duration",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7B7B7B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildControlledDropdown(
                  value: selectedPeriod,
                  items: periodOptions,
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value;
                      selectedDuration = '1';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                flex: 3,
                child: _buildControlledDropdown(
                  value: durationValue,
                  items: durationOptions,
                  labelBuilder: (duration) =>
                      "$duration ${selectedPeriod.toLowerCase()}${duration != '1' ? 's' : ''}",
                  onChanged: (value) {
                    setState(() => selectedDuration = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8DED6)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Current BOM overhead",
                    style: TextStyle(
                      color: Color(0xFF756A61),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  "₦${_formatAmount(overheadPreview)}",
                  style: const TextStyle(
                    color: Color(0xFFA16438),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlledDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String Function(String value)? labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    labelBuilder?.call(item) ?? item,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next == null) return;
            onChanged(next);
          },
        ),
      ),
    );
  }

  Widget _buildCostBreakdownSection(Map<String, double> pricing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Total",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildCostRow("Materials", pricing['materialTotal']!),
        const SizedBox(height: 12),
        _buildCostRow("Additional Costs", pricing['additionalTotal']!),
        const SizedBox(height: 12),

        if (pricingMethod == 'Method 2') ...[
          _buildCostRow(
            "Manufacturing Overhead (${_bomDurationLabel()})",
            pricing['overheadCost']!,
            isLoading: isLoadingOverhead,
          ),
          const SizedBox(height: 12),
        ],

        const Divider(),
        const SizedBox(height: 12),
        _buildCostRow("Cost Price", pricing['costPrice']!, isBold: true),
        const SizedBox(height: 12),
        _buildCostRow(
          "Markup Profit (${markupPercentage.toStringAsFixed(1)}%)",
          pricing['markupAmount'] ?? 0,
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildTotalHeroRow("Selling Price", pricing['sellingPrice']!),
      ],
    );
  }

  Widget _buildCostRow(
    String label,
    double value, {
    bool isLoading = false,
    bool isBold = false,
    bool isHighlight = false,
  }) {
    final textColor = isHighlight
        ? const Color(0xFFA16438)
        : const Color(0xFF302E2E);
    final weight = isBold ? FontWeight.w600 : FontWeight.w400;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final fontSize = isHighlight
            ? 18.0
            : compact
            ? 15.5
            : 16.5;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: weight,
                  height: 1.25,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Flexible(
                flex: 0,
                child: Text(
                  "₦${_formatAmount(value)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: weight,
                    height: 1.25,
                    color: textColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTotalHeroRow(String label, double value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Color(0xFFA16438),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "₦${_formatAmount(value)}",
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: Color(0xFFA16438),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    return NumberFormat.decimalPattern().format(value.round());
  }

  String _stripMeasurementFromLabel(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return '-';

    // Matches 1x10x144, 1"x10"x144", 0.25" x 48" x 96", 1/2x10x144, etc.
    final dimensionPattern = RegExp(
      r'(\d+(?:\.\d+)?|\d+\s*/\s*\d+)\s*(?:"|in|inch|inches|mm|cm|m|ft)?\s*[xX]\s*'
      r'(\d+(?:\.\d+)?|\d+\s*/\s*\d+)(?:\s*(?:"|in|inch|inches|mm|cm|m|ft)?\s*[xX]\s*'
      r'(\d+(?:\.\d+)?|\d+\s*/\s*\d+)\s*(?:"|in|inch|inches|mm|cm|m|ft)?)?',
    );

    final match = dimensionPattern.firstMatch(text);
    if (match == null) {
      return text;
    }

    var cleaned = text.substring(0, match.start).trim();
    cleaned = cleaned.replaceFirst(RegExp(r'[\s_\-"]+$'), '').trim();
    return cleaned.isEmpty ? text : cleaned;
  }

  // Material and Additional Cost card widgets remain the same...
  Widget _buildMaterialCard(Map<String, dynamic> item) {
    return Consumer(
      builder: (context, ref, _) {
        int quantity = 1;
        final q = item["quantity"];
        if (q is int) {
          quantity = q;
        } else if (q is double) {
          quantity = q.toInt();
        } else if (q is String) {
          quantity = int.tryParse(q) ?? 1;
        }

        final double price = _materialLineTotal(item);

        Widget buildRow(String label, String value) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF302E2E),
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF302E2E),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
            ],
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildRow(
                'Product Type',
                _stripMeasurementFromLabel(item["Product"]),
              ),
              const SizedBox(height: 12),
              buildRow(
                'Material Name',
                _stripMeasurementFromLabel(item["Materialname"]),
              ),
              const SizedBox(height: 12),
              buildRow('Width', item["Width"]?.toString() ?? "-"),
              const SizedBox(height: 12),
              buildRow('Length', item["Length"]?.toString() ?? "-"),
              const SizedBox(height: 12),
              buildRow('Thickness', item["Thickness"]?.toString() ?? "-"),
              const SizedBox(height: 12),
              buildRow('Unit', item["Unit"]?.toString() ?? "-"),
              const SizedBox(height: 12),
              buildRow('Square Meter', item["Sqm"]?.toString() ?? "-"),
              const SizedBox(height: 12),
              buildRow('Quantity', quantity.toString()),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        color: Color(0xFF302E2E),
                        fontSize: 16,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                    Text(
                      "₦${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Color(0xFF302E2E),
                        fontSize: 16,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdditionalCostCard(Map<String, dynamic> item) {
    final double amount =
        double.tryParse((item["amount"] ?? "0").toString()) ?? 0;

    Widget buildRow(String label, String value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF302E2E),
                fontSize: 16,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFF302E2E),
                fontSize: 16,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildRow('Type', item["type"] ?? "-"),
          const SizedBox(height: 12),
          buildRow('Description', item["description"] ?? "-"),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(
                    color: Color(0xFF302E2E),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                Text(
                  "₦${amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color(0xFF302E2E),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper adapter class for the calculator
class _CostItemAdapter {
  final double cost;
  final String period;
  final String category;
  final String description;

  _CostItemAdapter({
    required this.cost,
    required this.period,
    required this.category,
    required this.description,
  });

  // Getters for the calculator to access properties
  double get getCost => cost;
  String get getPeriod => period;
  String get getCategory => category;
  String get getDescription => description;
}
