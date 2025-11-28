import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/OverHead/View/AddOverhead.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';




class PricingSettingsManager {
  static const String _markupKey = 'pricing_markup_percentage';
  static const String _pricingMethodKey = 'pricing_method';
  static const String _workingDaysKey = 'factory_working_days_per_month';

  // Save markup percentage
  static Future<void> saveMarkup(double markupPercentage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_markupKey, markupPercentage);
    debugPrint("💾 Saved markup: $markupPercentage%");
  }

  // Get markup percentage (default: 30%)
  static Future<double> getMarkup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_markupKey) ?? 30.0;
  }

  // Save pricing method (Method 1 or Method 2)
  static Future<void> savePricingMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pricingMethodKey, method);
    debugPrint("💾 Saved pricing method: $method");
  }

  // Get pricing method (default: Method 1)
  static Future<String> getPricingMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pricingMethodKey) ?? 'Method 1';
  }

  // Save working days per month
  static Future<void> saveWorkingDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workingDaysKey, days);
    debugPrint("💾 Saved working days: $days");
  }

  // Get working days per month (default: 26 days)
  static Future<int> getWorkingDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_workingDaysKey) ?? 26;
  }
}
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

  // Pricing Settings
  double markupPercentage = 30.0;
  String pricingMethod = 'Method 1'; // Method 1 or Method 2
  int workingDaysPerMonth = 26;

  @override
  void initState() {
    super.initState();
    _loadOverheadCosts();
     _loadPricingSettings();
  }

  // Load pricing settings
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

  // 💰 METHOD 1: Calculate MOC (Manufacturing Overhead Cost) per day
  double calculateMOCPerDay() {
    if (overheadCosts.isEmpty) return 0.0;

    double yearlyTotal = 0.0;

    for (var overhead in overheadCosts) {
      final double cost = (overhead['cost'] ?? 0).toDouble();
      final String period = overhead['period'] ?? 'Monthly';

      // Convert all costs to yearly
      double yearlyCost = 0.0;

      switch (period.toLowerCase()) {
        case 'hourly':
          yearlyCost = cost * 24 * 365; // hours per year
          break;
        case 'daily':
          yearlyCost = cost * 365;
          break;
        case 'weekly':
          yearlyCost = cost * 52;
          break;
        case 'monthly':
          yearlyCost = cost * 12;
          break;
        case 'quarterly':
          yearlyCost = cost * 4;
          break;
        case 'yearly':
          yearlyCost = cost;
          break;
        default:
          yearlyCost = cost * 12; // Default to monthly
      }

      yearlyTotal += yearlyCost;
      
      debugPrint(
        "📊 ${overhead['category']}: ₦$cost/${period} → ₦${yearlyCost.toStringAsFixed(2)}/year",
      );
    }

    // Calculate MOC per day
    final monthlyMOC = yearlyTotal / 12;
    final dailyMOC = monthlyMOC / workingDaysPerMonth;

    debugPrint("📊 Yearly Total: ₦${yearlyTotal.toStringAsFixed(2)}");
    debugPrint("📊 Monthly MOC: ₦${monthlyMOC.toStringAsFixed(2)}");
    debugPrint("📊 Daily MOC: ₦${dailyMOC.toStringAsFixed(2)}");

    return dailyMOC;
  }

  // 💰 Calculate Manufacturing Overhead Cost based on duration
  double calculateManufacturingOverhead() {
    if (selectedDuration == null) return 0.0;

    final int duration = int.tryParse(selectedDuration!) ?? 0;
    if (duration == 0) return 0.0;

    final dailyMOC = calculateMOCPerDay();

    // Convert user's selected duration to days
    double durationInDays = 0.0;

    switch (selectedPeriod) {
      case 'Hour':
        durationInDays = duration / 24;
        break;
      case 'Day':
        durationInDays = duration.toDouble();
        break;
      case 'Week':
        durationInDays = duration * 7;
        break;
      case 'Month':
        durationInDays = duration * 30;
        break;
    }

    final totalMOC = dailyMOC * durationInDays;

    debugPrint(
      "💰 Manufacturing Overhead: ₦${dailyMOC.toStringAsFixed(2)}/day × $durationInDays days = ₦${totalMOC.toStringAsFixed(2)}",
    );

    return totalMOC;
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
      // METHOD 1: Cost Price = Materials + Other Costs + MOC (based on duration)
      overheadCost = calculateManufacturingOverhead();
      costPrice = materialTotal + additionalTotal + overheadCost;
      
      // Add markup to get selling price
      sellingPrice = costPrice * (1 + (markupPercentage / 100));

      debugPrint("💵 METHOD 1:");
      debugPrint("   Materials: ₦${materialTotal.toStringAsFixed(2)}");
      debugPrint("   Additional Costs: ₦${additionalTotal.toStringAsFixed(2)}");
      debugPrint("   Manufacturing Overhead: ₦${overheadCost.toStringAsFixed(2)}");
      debugPrint("   Cost Price: ₦${costPrice.toStringAsFixed(2)}");
      debugPrint("   Markup: $markupPercentage%");
      debugPrint("   Selling Price: ₦${sellingPrice.toStringAsFixed(2)}");
    } else {
      // METHOD 2: Cost Price = Materials + Other Costs (NO MOC)
      costPrice = materialTotal + additionalTotal;
      overheadCost = 0; // MOC not included in Method 2
      
      // Add markup to get selling price
      sellingPrice = costPrice * (1 + (markupPercentage / 100));

      debugPrint("💵 METHOD 2:");
      debugPrint("   Materials: ₦${materialTotal.toStringAsFixed(2)}");
      debugPrint("   Additional Costs: ₦${additionalTotal.toStringAsFixed(2)}");
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

  // Show pricing method selector dialog
  Future<void> _showPricingMethodDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Pricing Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<String>(
              title: const Text('Method 1'),
              subtitle: const Text('Include Manufacturing Overhead Cost'),
              value: 'Method 1',
              groupValue: pricingMethod,
              onChanged: (value) {
                setState(() => pricingMethod = value!);
                PricingSettingsManager.savePricingMethod(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Method 2'),
              subtitle: const Text('Direct Markup (No MOC)'),
              value: 'Method 2',
              groupValue: pricingMethod,
              onChanged: (value) {
                setState(() => pricingMethod = value!);
                PricingSettingsManager.savePricingMethod(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Create Quotation and Continue
  Future<void> _createQuotationAndContinue(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) async {
    try {
      final pricing = calculatePricing(materials, additionalCosts);

      // Get product data
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

      // Create quotation
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
            icon: const Icon(Icons.settings),
            onPressed: _showPricingMethodDialog,
            tooltip: 'Pricing Method',
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

              // Pricing Method Indicator
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
                        "$pricingMethod: ${pricingMethod == 'Method 1' ? 'With Manufacturing Overhead' : 'Direct Markup'} • ${markupPercentage.toStringAsFixed(1)}% Markup",
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

              // Expected Duration Section (only show for Method 1)
              if (pricingMethod == 'Method 1') ...[
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

  // ✅ Cost Breakdown Section (Cost Price, Overhead, Selling Price)
 // Cost Breakdown Section
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
        
        if (pricingMethod == 'Method 1') ...[
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
            "₦${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isHighlight ? const Color(0xFFA16438) : const Color(0xFF302E2E),
            ),
          ),
      ],
    );
  }

  // ✅ Material Card
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
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF302E2E),
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
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

  // ✅ Additional Cost Card
  Widget _buildAdditionalCostCard(Map<String, dynamic> item) {
    final double amount =
        double.tryParse((item["amount"] ?? "0").toString()) ?? 0;

    Widget buildRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF302E2E),
              fontSize: 16,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w400,
              height: 1.50,
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
