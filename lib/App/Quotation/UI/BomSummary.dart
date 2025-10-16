import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Widget/BomScard.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';


class BOMSummary extends ConsumerStatefulWidget {
  const BOMSummary({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BOMSummaryState();
}

class _BOMSummaryState extends ConsumerState<BOMSummary> {
  @override
  Widget build(BuildContext context) {
    // 🧩 Step 1: Watch provider
    final materialData = ref.watch(materialProvider);

    // 🧩 Step 2: Extract materials and additional costs
    final materials =
        List<Map<String, dynamic>>.from(materialData["materials"] ?? []);
    final additionalCosts =
        List<Map<String, dynamic>>.from(materialData["additionalCosts"] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "BOM Summary",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(title: "Summary"),

              const SizedBox(height: 20),

              // 🧩 Materials Section
              const Text(
                "Materials",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (materials.isEmpty)
                const Text(
                  "No materials added yet.",
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...materials.map((item) => BOMSummaryCard(item: item)),

              const SizedBox(height: 30),

              // 🧩 Additional Costs Section
              const Text(
                "Additional Costs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (additionalCosts.isEmpty)
                const Text(
                  "No additional costs added yet.",
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...additionalCosts.map((item) => BOMSummaryCard(item: item)),

              const SizedBox(height: 40),

  
              if (materials.isNotEmpty || additionalCosts.isNotEmpty)
                _buildTotalSection(materials, additionalCosts),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTotalSection(
      List<Map<String, dynamic>> materials, List<Map<String, dynamic>> additionalCosts) {
    double materialTotal = 0;
    double additionalTotal = 0;

    for (var m in materials) {
      final price = double.tryParse(m["price"].toString()) ?? 0;
      materialTotal += price;
    }

    for (var c in additionalCosts) {
      final amount = double.tryParse(c["amount"].toString()) ?? 0;
      additionalTotal += amount;
    }

    final total = materialTotal + additionalTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
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
          const Divider(thickness: 1, color: Colors.grey),
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
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          Text(
            "₦${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
