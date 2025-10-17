import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
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

  const SecQuote({
    super.key,
    required this.name,
    required this.address,
    required this.nearestBusStop,
    required this.phone,
    required this.email,
    required this.description,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SecQuoteState();
}

class _SecQuoteState extends ConsumerState<SecQuote> {
  bool isLoading = false; // loading state

  @override
  Widget build(BuildContext context) {
    final materialData = ref.watch(materialProvider);
    final materials = List<Map<String, dynamic>>.from(materialData["materials"] ?? []);
    final additionalCosts = List<Map<String, dynamic>>.from(materialData["additionalCosts"] ?? []);

    final materialItems = materials.map((m) {
      final quantity = int.tryParse(m["quantity"].toString()) ?? 1;
      final price = double.tryParse(m["Price"].toString()) ?? 0;
      final total = price * quantity;

      return QuotationItem(
        product: m["Product"] ?? "Unnamed",
        description: m["Materialname"] ?? "",
        quantity: quantity,
        unitPrice: "₦${price.toStringAsFixed(2)}",
        total: "₦${total.toStringAsFixed(2)}",
      );
    }).toList();

    final costItems = additionalCosts.map((c) {
      final amount = double.tryParse(c["amount"].toString()) ?? 0;
      return QuotationItem(
        product: c["type"] ?? "Additional",
        description: c["description"] ?? "",
        quantity: 1,
        unitPrice: "₦${amount.toStringAsFixed(2)}",
        total: "₦${amount.toStringAsFixed(2)}",
      );
    }).toList();

    final allItems = [...materialItems, ...costItems];

    final totalSum = allItems.fold<double>(0, (sum, item) {
      final val = double.tryParse(item.total.replaceAll(RegExp(r'[₦,]'), '')) ?? 0;
      return sum + val;
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
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
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: isLoading ? "Saving..." : "Save",
                          icon: isLoading ? null : Icons.save,
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() => isLoading = true); // start loading

                                  final bomService = BOMService();

                                  // Prepare items
                                  final items = materials.map((m) {
                                    final quantity =
                                        int.tryParse(m["quantity"].toString()) ?? 1;
                                    final price =
                                        double.tryParse(m["Price"].toString()) ?? 0;

                                    return {
                                      "woodType": m["Product"] ?? "",
                                      "foamType": null,
                                      "width": double.tryParse(m["Width"].toString()) ?? 0,
                                      "height": double.tryParse(m["Height"]?.toString() ?? "0") ?? 0,
                                      "length": double.tryParse(m["Length"].toString()) ?? 0,
                                      "thickness": double.tryParse(m["Thickness"].toString()) ?? 0,
                                      "unit": m["Unit"] ?? "cm",
                                      "squareMeter": double.tryParse(m["Sqm"].toString()) ?? 0,
                                      "quantity": quantity,
                                      "costPrice": price,
                                      "sellingPrice": price,
                                      "description": m["Materialname"] ?? "",
                                      "image": "",
                                    };
                                  }).toList();

                                  // Prepare service
                                  final totalServicePrice = materials.fold<double>(
                                      0,
                                      (sum, m) =>
                                          sum + (double.tryParse(m["Price"].toString()) ?? 0) *
                                              (int.tryParse(m["quantity"].toString()) ?? 1));
                                  final service = {
                                    "product": "Materials Service",
                                    "quantity": 1,
                                    "discount": 0,
                                    "totalPrice": totalServicePrice,
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

                                  setState(() => isLoading = false); // stop loading

                                  if (response["success"] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("✅ Quotation created successfully")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "❌ Failed: ${response["message"] ?? "Error"}")),
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: "Send to Client",
                          onPressed: () {
                         
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
                  
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

