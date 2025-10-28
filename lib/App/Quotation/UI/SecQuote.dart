import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/Widget/QuoInfo.dart';
import 'package:wworker/App/Quotation/Widget/QuoTable.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';



class SecQuote extends ConsumerStatefulWidget {
  final String name;
  final String address;
  final String nearestBusStop;
  final String phone;
  final String email;
  final String description;
  final List<Map<String, dynamic>> selectedQuotations;
  final Map<String, int> quotationQuantities;

  const SecQuote({
    super.key,
    required this.name,
    required this.address,
    required this.nearestBusStop,
    required this.phone,
    required this.email,
    required this.description,
    required this.selectedQuotations,
    required this.quotationQuantities,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SecQuoteState();
}

class _SecQuoteState extends ConsumerState<SecQuote> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ✅ Each quotation as a summary
    List<QuotationItem> allItems = [];

    for (var quotation in widget.selectedQuotations) {
      final quotationId = quotation["id"] as String;
      final quantity = widget.quotationQuantities[quotationId] ?? 1;
      final product = quotation["product"] ?? {};

      // Total cost of materials + additional costs
      final materials = List<Map<String, dynamic>>.from(quotation["materials"] ?? []);
      final additionalCosts = List<Map<String, dynamic>>.from(quotation["additionalCosts"] ?? []);

      double materialCost = materials.fold<double>(
        0,
        (sum, m) => sum + (double.tryParse(m["Price"]?.toString() ?? "0") ?? 0),
      );

      double additionalCost = additionalCosts.fold<double>(
        0,
        (sum, c) => sum + (double.tryParse(c["amount"]?.toString() ?? "0") ?? 0),
      );

      double totalCostPerQuotation = (materialCost + additionalCost) * quantity;

      allItems.add(
        QuotationItem(
          product: product["name"] ?? "Unknown Product",
          description: product["description"] ?? "",
          quantity: quantity,
          unitPrice: "₦${(materialCost + additionalCost).toStringAsFixed(2)}",
          total: "₦${totalCostPerQuotation.toStringAsFixed(2)}",
        ),
      );
    }

    final totalSum = allItems.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.total.replaceAll(RegExp(r'[₦,]'), '')) ?? 0),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Quotation Details")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            children: [
              QuotationInfo(
                title: "Company Information",
                contact: ContactInfo(
                  name: "Sumit Nova Trust Ltd",
                  address: "K3, plaza, New Garage, Ibadan.",
                  nearestBusStop: "Alao Akala Expressway",
                  phone: "07034567890",
                  email: "admin@sumitnovatrustltd.com",
                ),
              ),
              const SizedBox(height: 20),
              QuotationInfo(
                title: "Client Information",
                contact: ContactInfo(
                  name: widget.name,
                  address: widget.address,
                  nearestBusStop: widget.nearestBusStop,
                  phone: widget.phone,
                  email: widget.email,
                ),
              ),
              const SizedBox(height: 20),
              QuotationTable(items: allItems),
      
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: isLoading ? "Saving..." : "Save",
                        icon: isLoading ? null : Icons.save,
                        onPressed: isLoading ? null : () => _saveQuotation(allItems, totalSum),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: "Send to Client",
                        onPressed: () {
                          // TODO: implement sending functionality
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Download PDF",
                outlined: true,
                onPressed: () {
                  // TODO: implement PDF download
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuotation(List<QuotationItem> allItems, double totalSum) async {
    setState(() => isLoading = true);

    final bomService = BOMService();

    // Flatten materials for backend
    final items = widget.selectedQuotations.map((quotation) {
      final quotationId = quotation["id"] as String;
      final quantity = widget.quotationQuantities[quotationId] ?? 1;
      final materials = List<Map<String, dynamic>>.from(quotation["materials"] ?? []);

      return materials.map((m) {
        final materialQty = int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1;
        final price = double.tryParse(m["Price"]?.toString() ?? "0") ?? 0;

        return {
          "woodType": m["Product"] ?? "",
          "foamType": null,
          "width": double.tryParse(m["Width"]?.toString() ?? "0") ?? 0,
          "height": double.tryParse(m["Height"]?.toString() ?? "0") ?? 0,
          "length": double.tryParse(m["Length"]?.toString() ?? "0") ?? 0,
          "thickness": double.tryParse(m["Thickness"]?.toString() ?? "0") ?? 0,
          "unit": m["Unit"] ?? "cm",
          "squareMeter": double.tryParse(m["Sqm"]?.toString() ?? "0") ?? 0,
          "quantity": materialQty * quantity,
          "costPrice": price,
          "sellingPrice": price,
          "description": m["Materialname"] ?? "",
          "image": "",
        };
      }).toList();
    }).expand((e) => e).toList();

    final service = {
      "product": "Materials Service",
      "quantity": 1,
      "discount": 0,
      "totalPrice": totalSum,
    };

    final response = await bomService.createQuotation(
      clientName: widget.name,
      clientAddress: widget.address,
      nearestBusStop: widget.nearestBusStop,
      phoneNumber: widget.phone,
      email: widget.email,
      description: widget.description,
      items: items,
      service: service,
      discount: 0.0,
    );

    setState(() => isLoading = false);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Quotation created successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: ${response["message"] ?? "Error"}")),
      );
    }
  }
}

