import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/OverHead/View/AddOverhead.dart';
import 'package:wworker/App/OverHead/Widget/OCCalculator.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
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
  bool isLoading = false;

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
    final markupController =
        TextEditingController(text: markupPercentage.toString());
    final workingDaysController =
        TextEditingController(text: workingDaysPerMonth.toString());
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                final markup = double.tryParse(
                                      markupController.text,
                                    ) ??
                                    30.0;
                                final workingDays = int.tryParse(
                                      workingDaysController.text,
                                    ) ??
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

                                if (mounted) Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA16438),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
            color:
                selected ? const Color(0xFFA16438) : Colors.grey.shade300,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
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
      final costs = await OverheadCostManager.getOverheadCosts();

      setState(() {
        overheadCosts = costs;
        isLoadingOverhead = false;
      });

      debugPrint("📊 Loaded ${costs.length} overhead costs");
    } catch (e) {
      debugPrint("⚠️ Error loading overhead costs: $e");
      setState(() {
        overheadCosts = [];
        isLoadingOverhead = false;
      });
    }
  }

  // 💰 Calculate Manufacturing Overhead with proper period conversion
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
        debugPrint("💰   ${cost['description']}: ₦${cost['cost']}/${cost['period']}");
      }
      debugPrint("💰 ============================================");

      // Convert overhead costs to _CostItemAdapter format for calculator
      final items = overheadCosts.map((cost) {
        final adapter = _CostItemAdapter(
          cost: (cost['cost'] as num).toDouble(),
          period: cost['period'] as String,
          category: cost['category'] as String,
          description: cost['description'] as String,
        );
        debugPrint("💰 Created adapter: ${adapter.description} - ₦${adapter.cost}/${adapter.period}");
        return adapter;
      }).toList();

      // STEP 1: Convert all overhead costs to the selected period
      String targetPeriod = selectedPeriod; // 'Hour', 'Day', 'Week', or 'Month'
      
      debugPrint("💰 ");
      debugPrint("💰 TARGET PERIOD: $targetPeriod");
      debugPrint("💰 DURATION: $duration $targetPeriod(s)");
      debugPrint("💰 ");

      double overheadPerPeriod = OverheadCostCalculator.calculateTotalForDuration(
        items,
        targetPeriod,
      );

      debugPrint("💰 Calculated overhead per $targetPeriod: ₦${overheadPerPeriod.toStringAsFixed(2)}");

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
        debugPrint("💰   ${item.description}: ₦${item.cost}/${item.period} → ₦${convertedCost.toStringAsFixed(2)}/$targetPeriod");
      }
      debugPrint("💰 ");
      debugPrint("💰 CALCULATION:");
      debugPrint("💰   Total Overhead per $targetPeriod: ₦${overheadPerPeriod.toStringAsFixed(2)}");
      debugPrint("💰   × Duration: $duration $selectedPeriod(s)");
      debugPrint("💰   = TOTAL MANUFACTURING OVERHEAD: ₦${totalOverhead.toStringAsFixed(2)}");
      debugPrint("💰 ============================================");

      return totalOverhead;
    } catch (e, stackTrace) {
      debugPrint("⚠️ Error calculating overhead: $e");
      debugPrint("⚠️ Stack trace: $stackTrace");
      return 0.0;
    }
  }

  // 📊 Calculate Pricing based on selected method
  Map<String, double> calculatePricing(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    // Calculate material total
    double materialTotal = 0;
    for (var m in materials) {
      final price = double.tryParse(m["Price"].toString()) ?? 0;
      final qty = int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1;
      materialTotal += price * qty;
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
      debugPrint("   Manufacturing Overhead: ₦${overheadCost.toStringAsFixed(2)}");
      debugPrint("   Cost Price: ₦${costPrice.toStringAsFixed(2)}");
      debugPrint("   Markup: $markupPercentage%");
      debugPrint("   Selling Price: ₦${sellingPrice.toStringAsFixed(2)}");
    }

    return {
      'materialTotal': materialTotal,
      'additionalTotal': additionalTotal,
      'costPrice': costPrice,
      'overheadCost': overheadCost,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Quotation created successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Nav.pop();
        Nav.pop();
        Nav.pop();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(title: "Summary"),
              const SizedBox(height: 20),

              // Pricing Method Indicator (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA16438)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFA16438)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "$pricingMethod: ${pricingMethod == 'Method 1' ? 'Direct Markup' : 'With Manufacturing Overhead'} • ${markupPercentage.toStringAsFixed(1)}% Markup",
                        style: const TextStyle(
                          color: Color(0xFFA16438),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Materials",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (materials.isEmpty)
                const Text("No materials added yet.")
              else
                ...materials.map((m) => _buildMaterialCard(m)),

              const SizedBox(height: 30),

              const Text(
                "Additional Costs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (additionalCosts.isEmpty)
                const Text("No additional costs added yet.")
              else
                ...additionalCosts.map((c) => _buildAdditionalCostCard(c)),

              const SizedBox(height: 40),

              // Expected Duration Section (only show for Method 2)
              if (pricingMethod == 'Method 2') ...[
                _buildExpectedDurationSection(),
                const SizedBox(height: 30),
              ],

              // Cost Breakdown Section
              _buildCostBreakdownSection(pricing),

              const SizedBox(height: 40),

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

  Widget _buildExpectedDurationSection() {
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
                child: DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: periodOptions
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value!;
                      selectedDuration = '1';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: selectedDuration,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: durationOptions
                      .map(
                        (duration) => DropdownMenuItem(
                          value: duration,
                          child: Text(
                            "$duration ${selectedPeriod.toLowerCase()}${duration != '1' ? 's' : ''}",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDuration = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
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
            "Manufacturing Overhead",
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
          "Markup ($markupPercentage%)",
          pricing['sellingPrice']! - pricing['costPrice']!,
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildCostRow(
          "Selling Price",
          pricing['sellingPrice']!,
          isBold: true,
          isHighlight: true,
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isHighlight ? const Color(0xFFA16438) : const Color(0xFF302E2E),
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            "₦${_formatAmount(value)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isHighlight ? const Color(0xFFA16438) : const Color(0xFF302E2E),
            ),
          ),
      ],
    );
  }

  String _formatAmount(double value) {
    return NumberFormat.decimalPattern().format(value.round());
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

        final double price =
            double.tryParse((item["Price"] ?? "0").toString()) ?? 0;

        Widget buildRow(String label, String value) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w400, height: 1.50)),
              Text(value, style: const TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w400, height: 1.50)),
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
              buildRow('Product Type', item["Product"] ?? "-"),
              const SizedBox(height: 12),
              buildRow('Material Name', item["Materialname"] ?? "-"),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Price', style: TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w400, height: 1.50)),
                    Text("₦${price.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w600)),
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
    final double amount = double.tryParse((item["amount"] ?? "0").toString()) ?? 0;

    Widget buildRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w400, height: 1.50)),
          Text(value, style: const TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w400, height: 1.50)),
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
            decoration: ShapeDecoration(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount', style: TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w400, height: 1.50)),
                Text("₦${amount.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF302E2E), fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.w600)),
              ],
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
