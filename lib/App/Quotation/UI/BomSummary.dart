import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/UI/FirstQuote.dart';
import 'package:wworker/App/Quotation/Widget/BomScard.dart';
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

      final firstMaterial = materials.first;
      final productName = firstMaterial["Product"] ?? "BOM Item";

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
    // 🔹 Parse quantity safely
    "quantity": int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1,
    "description": m["Materialname"] ?? "",
  };
}).toList();


      final createResponse = await _bomService.createBOM(
        name: productName,
        description: description,
        materials: formattedMaterials,
      );

      if (createResponse["success"] == true) {
        final bomId = createResponse["data"]["_id"];
        debugPrint("✅ BOM created with ID: $bomId");

        if (additionalCosts.isNotEmpty) {
          final costResponse = await _bomService.addAdditionalCost(
            bomId: bomId,
            additionalCosts: additionalCosts,
          );
          debugPrint("💰 Additional costs added: $costResponse");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ BOM successfully created!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ Failed: ${createResponse["message"] ?? "Error"}",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error creating BOM: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ Unexpected error: $e")));
      }
    } finally {
      setState(() => isLoading = false);
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
                ...materials.map(
                  (m) => BOMSummaryCard(
                    item: m,
                    onQuantityChanged: () {
                      setState(
                        () {},
                      ); 
                    },
                  ),
                ),

              const SizedBox(height: 30),

              const Text(
                "Additional Costs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (additionalCosts.isEmpty)
                const Text("No additional costs added yet.")
              else
                ...additionalCosts.map(
                  (c) => BOMSummaryCard(
                    item: c,
                    onQuantityChanged: () {
                      setState(() {});
                    },
                  ),
                ),

              const SizedBox(height: 40),
              if (materials.isNotEmpty || additionalCosts.isNotEmpty)
                _buildTotalSection(materials, additionalCosts),

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
                onPressed: () {
                  Nav.push(FirstQuote());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    double materialTotal = 0;
    double additionalTotal = 0;

for (var m in materials) {
  final price = double.tryParse(m["Price"].toString()) ?? 0;
  final qty = int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1;
  materialTotal += price * qty;
}


    for (var c in additionalCosts) {
      final amount = double.tryParse(c["amount"].toString()) ?? 0;
      additionalTotal += amount;
    }

    final total = materialTotal + additionalTotal;

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
            "Total Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildTotalRow("Materials Total", materialTotal),
          _buildTotalRow("Additional Costs Total", additionalTotal),
          const Divider(),
          _buildTotalRow("Overall Total", total, bold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            "₦${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
