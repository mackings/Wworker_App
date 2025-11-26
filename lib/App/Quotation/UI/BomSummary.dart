import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/OverHead/View/AddOverhead.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

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
  String? selectedDuration = '24';
  String selectedPeriod = 'Day'; // Hour, Day, Week, Month
  final List<String> periodOptions = ['Hour', 'Day', 'Week', 'Month'];

  // Duration options (1-365 for days/hours, 1-52 for weeks, 1-12 for months)
  List<String> get durationOptions {
    switch (selectedPeriod) {
      case 'Hour':
        return List.generate(
          24 * 30,
          (index) => '${index + 1}',
        ); // Up to 720 hours (30 days)
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

  @override
  void initState() {
    super.initState();
    _loadOverheadCosts();
  }

  // 📊 Load Overhead Costs from API
  Future<void> _loadOverheadCosts() async {
    setState(() => isLoadingOverhead = true);

    try {
      // Replace with your actual API call
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

  // 💰 Calculate Overhead Cost Based on Duration and Period
  double calculateProportionalOverhead() {
    if (overheadCosts.isEmpty || selectedDuration == null) return 0.0;

    final int duration = int.tryParse(selectedDuration!) ?? 0;
    if (duration == 0) return 0.0;

    double totalOverhead = 0.0;

    for (var overhead in overheadCosts) {
      final double cost = (overhead['cost'] ?? 0).toDouble();
      final String period = overhead['period'] ?? 'Monthly';

      // Convert overhead cost to daily rate
      double dailyRate = 0.0;

      switch (period.toLowerCase()) {
        case 'hourly':
          dailyRate = cost * 24; // 24 hours in a day
          break;
        case 'daily':
          dailyRate = cost;
          break;
        case 'weekly':
          dailyRate = cost / 7;
          break;
        case 'monthly':
          dailyRate = cost / 30; // Approximate 30 days per month
          break;
        case 'yearly':
          dailyRate = cost / 365;
          break;
        default:
          dailyRate = cost / 30; // Default to monthly
      }

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

      // Calculate proportional overhead
      final proportionalCost = dailyRate * durationInDays;
      totalOverhead += proportionalCost;

      debugPrint(
        "📊 ${overhead['category']}: ₦$cost/${period} → ₦${dailyRate.toStringAsFixed(2)}/day × $durationInDays days = ₦${proportionalCost.toStringAsFixed(2)}",
      );
    }

    return totalOverhead;
  }

  Future<void> _addBOMToServer(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) async {
    setState(() => isLoading = true);

    try {
      if (materials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one material.")),
        );
        setState(() => isLoading = false);
        return;
      }

      // ✅ Get productId from quotationSummaryProvider
      final quotationState = ref.read(quotationSummaryProvider);
      final productData = quotationState["product"];

      if (productData == null || productData["productId"] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Product ID not found. Please select a product."),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final String productId = productData["productId"];
      final productName = productData["name"] ?? "BOM Item";

      final now = DateTime.now();
      final formattedDate = DateFormat("d MMMM yyyy, h:mm a").format(now);
      final description = "$productName created on $formattedDate";

      final formattedMaterials = materials.map((m) {
        return {
          "woodType": m["Product"] ?? "",
          "foamType": null,
          "type": m["Materialname"] ?? "",
          "width": double.tryParse(m["Width"].toString()) ?? 0,
          "height": double.tryParse(m["Height"]?.toString() ?? "0") ?? 0,
          "length": double.tryParse(m["Length"].toString()) ?? 0,
          "thickness": double.tryParse(m["Thickness"].toString()) ?? 0,
          "unit": m["Unit"] ?? "cm",
          "squareMeter": double.tryParse(m["Sqm"].toString()) ?? 0,
          "price": double.tryParse(m["Price"].toString()) ?? 0,
          "quantity": int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1,
          "description": m["Materialname"] ?? "",
        };
      }).toList();

      // ✅ Format additional costs with name field
      final formattedAdditionalCosts = additionalCosts.map((c) {
        return {
          "name": c["type"] ?? "Additional Cost",
          "type": c["type"] ?? "",
          "description": c["description"] ?? "",
          "amount": double.tryParse(c["amount"]?.toString() ?? "0") ?? 0,
        };
      }).toList();

      debugPrint("📤 Creating BOM with productId: $productId");
      debugPrint("📦 Materials: ${formattedMaterials.length}");
      debugPrint("💰 Additional Costs: ${formattedAdditionalCosts.length}");

      // ✅ Create BOM with productId and additionalCosts
      final createResponse = await _bomService.createBOM(
        name: productName,
        description: description,
        productId: productId,
        materials: formattedMaterials,
        additionalCosts: formattedAdditionalCosts.isNotEmpty
            ? formattedAdditionalCosts
            : null,
      );

      if (createResponse["success"] == true) {
        final bomData = createResponse["data"];
        debugPrint("✅ BOM created successfully!");
        debugPrint("📋 BOM ID: ${bomData["_id"]}");
        debugPrint("💵 Total Cost: ${bomData["totalCost"]}");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ BOM successfully created!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ Failed: ${createResponse["message"] ?? "Unknown error"}",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error creating BOM: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Unexpected error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅ Create Quotation with Selling Price and Continue
  Future<void> _createQuotationAndContinue(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) async {
    try {
      // Calculate totals
      double materialTotal = 0;
      for (var m in materials) {
        final price = double.tryParse(m["Price"].toString()) ?? 0;
        final qty = int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1;
        materialTotal += price * qty;
      }

      double additionalTotal = 0;
      for (var c in additionalCosts) {
        final amount = double.tryParse(c["amount"].toString()) ?? 0;
        additionalTotal += amount;
      }

      final costPrice = materialTotal + additionalTotal;
      final overheadCost = calculateProportionalOverhead();
      final sellingPrice = costPrice + overheadCost;

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

      // Create quotation with selling price
      final newQuotation = {
        "product": productData,
        "materials": materials,
        "additionalCosts": additionalCosts,
        "costPrice": costPrice,
        "overheadCost": overheadCost,
        "sellingPrice": sellingPrice,
        "expectedDuration": selectedDuration,
        "expectedPeriod": selectedPeriod,
      };

      await quotationNotifier.addNewQuotation(newQuotation);

      debugPrint(
        "✅ Quotation created with selling price: ₦${sellingPrice.toStringAsFixed(2)}",
      );
      debugPrint(newQuotation.toString());

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
      

       // Nav.pushReplacement(AllQuotations());

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(title: "Summary"),
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

              // ✅ Expected Duration Section (Period + Duration)
              _buildExpectedDurationSection(),

              const SizedBox(height: 30),

              // ✅ Cost Breakdown Section (Only this one)
              _buildCostBreakdownSection(materials, additionalCosts),

              const SizedBox(height: 40),

              CustomButton(
                text: "Add to BOM",
                outlined: true,
                loading: isLoading,
                onPressed: () => _addBOMToServer(materials, additionalCosts),
              ),

              const SizedBox(height: 20),
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

  // ✅ Expected Duration Section (Period + Duration Dropdowns)
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

          // Period Selector (Hour, Day, Week, Month)
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
                    enabledBorder: OutlineInputBorder(
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
                      selectedDuration = '1'; // Reset to 1 when period changes
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Duration Number Selector
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text("Select duration"),
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
  Widget _buildCostBreakdownSection(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    // Calculate totals
    double materialTotal = 0;
    for (var m in materials) {
      final price = double.tryParse(m["Price"].toString()) ?? 0;
      final qty = int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1;
      materialTotal += price * qty;
    }

    double additionalTotal = 0;
    for (var c in additionalCosts) {
      final amount = double.tryParse(c["amount"].toString()) ?? 0;
      additionalTotal += amount;
    }

    final costPrice = materialTotal + additionalTotal;
    final overheadCost = calculateProportionalOverhead();
    final sellingPrice = costPrice + overheadCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Total",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildCostRow("Cost Price", costPrice),
        const SizedBox(height: 12),
        _buildCostRow(
          "Overhead Cost",
          overheadCost,
          isLoading: isLoadingOverhead,
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildCostRow("Selling Price", sellingPrice, isBold: true),
      ],
    );
  }

  Widget _buildCostRow(
    String label,
    double value, {
    bool isLoading = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF302E2E),
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
              color: const Color(0xFF302E2E),
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
