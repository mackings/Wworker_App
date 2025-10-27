import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';

class QuotationSummary extends ConsumerWidget {
  const QuotationSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(quotationSummaryProvider);

    final product = data["product"];
    final materials = List<Map<String, dynamic>>.from(data["materials"] ?? []);
    final additionalCosts =
        List<Map<String, dynamic>>.from(data["additionalCosts"] ?? []);

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text("No product found")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quotation Summary")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              QuoteGlanceCard(
                imageUrl: product["image"],
                productName: product["name"],
                bomNo: product["productId"],
                description: product["description"],
                costPrice: _calculateCost(materials, additionalCosts),
                sellingPrice: _calculateSelling(materials, additionalCosts),
                quantity: 1,
                onIncrease: () {},
                onDecrease: () {},
                onDelete: () {},
              ),
              const SizedBox(height: 30),
              Text("🪵 Materials (${materials.length})"),
              ...materials.map((m) => ListTile(
                    title: Text(m["Woodtype"] ?? ""),
                    subtitle: Text(
                        "W:${m["Width"]} x L:${m["Length"]} x Th:${m["Thickness"]} ${m["Unit"]}"),
                    trailing: Text("₦${m["Price"]}"),
                  )),
              const SizedBox(height: 20),
              Text("💰 Additional Costs (${additionalCosts.length})"),
              ...additionalCosts.map((c) => ListTile(
                    title: Text(c["title"] ?? "Cost"),
                    trailing: Text("₦${c["amount"] ?? 0}"),
                  )),
            ],
          ),
        ),
      ),
    );
  }

double _calculateCost(List materials, List additional) {
  double materialSum = materials.fold<double>(
    0,
    (sum, item) => sum + (double.tryParse(item["Price"].toString()) ?? 0.0),
  );

  double addSum = additional.fold<double>(
    0,
    (sum, item) => sum + (double.tryParse(item["amount"].toString()) ?? 0.0),
  );

  return materialSum + addSum;
}


  double _calculateSelling(List materials, List additional) {
    final base = _calculateCost(materials, additional);
    return base * 1.2; // 20% markup (for demo)
  }
}
