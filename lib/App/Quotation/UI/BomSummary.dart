import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
          "name": c["type"] ?? "Additional Cost", // ✅ Added name field
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
                  final quotationNotifier = ref.read(
                    quotationSummaryProvider.notifier,
                  );

                  quotationNotifier.setMaterials(materials);
                  quotationNotifier.setAdditionalCosts(additionalCosts);

                  //Nav.push(QuotationSummary());
                  Nav.pushReplacement(AllQuotations());
                },
              ),
            ],
          ),
        ),
      ),
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
