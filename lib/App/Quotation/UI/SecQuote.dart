import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Widget/QuoInfo.dart';
import 'package:wworker/App/Quotation/Widget/QuoTable.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

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
  
  // ✅ Company data from SharedPreferences
  String companyName = 'Your Company';
  String companyEmail = '';
  String companyPhone = '';
  String companyAddress = '';
  bool isLoadingCompanyData = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  // ✅ Load company data from SharedPreferences
  Future<void> _loadCompanyData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!mounted) return;
    setState(() {
      companyName = prefs.getString('companyName') ?? 'Your Company';
      companyEmail = prefs.getString('companyEmail') ?? '';
      companyPhone = prefs.getString('companyPhoneNumber') ?? '';
      companyAddress = prefs.getString('companyAddress') ?? '';
      
      isLoadingCompanyData = false;
    });
  }

  // ✅ Get cost price from quotation
  double _getCostPrice(Map<String, dynamic> quotation) {
    if (quotation.containsKey("costPrice")) {
      return (quotation["costPrice"] as num?)?.toDouble() ?? 0.0;
    }

    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialCost = materials.fold<double>(
      0,
      (sum, m) => sum + (double.tryParse(m["Price"]?.toString() ?? "0") ?? 0),
    );

    double additionalCost = additionalCosts.fold<double>(
      0,
      (sum, c) => sum + (double.tryParse(c["amount"]?.toString() ?? "0") ?? 0),
    );

    return materialCost + additionalCost;
  }

  // ✅ Get selling price from quotation (cost + overhead)
  double _getSellingPrice(Map<String, dynamic> quotation) {
    if (quotation.containsKey("sellingPrice")) {
      return (quotation["sellingPrice"] as num?)?.toDouble() ?? 0.0;
    }

    // Fallback to cost price for backward compatibility
    return _getCostPrice(quotation);
  }

  double _calculateTotalCost(Map<String, dynamic> quotation, int quantity) {
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = 0.0;
    int disabledCount = 0;
    for (final material in materials) {
      final price =
          double.tryParse((material["Price"] ?? "0").toString()) ?? 0.0;
      final materialQty =
          int.tryParse((material["quantity"] ?? "1").toString()) ?? 1;
      final disableIncrement = material["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quantity;
      if (disableIncrement) disabledCount += 1;
      materialTotal += price * materialQty * multiplier;
    }

    double additionalTotal = 0.0;
    for (final cost in additionalCosts) {
      final amount =
          double.tryParse((cost["amount"] ?? "0").toString()) ?? 0.0;
      additionalTotal += amount * quantity;
    }

    final total = materialTotal + additionalTotal;
    debugPrint(
      "📊 [SEC QUOTE] qty=$quantity materials=${materials.length} "
      "disabled=$disabledCount materialTotal=${materialTotal.toStringAsFixed(2)} "
      "additionalTotal=${additionalTotal.toStringAsFixed(2)} "
      "total=${total.toStringAsFixed(2)}",
    );
    return total;
  }

  double _calculateTotalSellingPrice(Map<String, dynamic> quotation, int quantity) {
    final baseCost = _getCostPrice(quotation);
    final baseSelling = _getSellingPrice(quotation);
    if (baseCost <= 0) return 0.0;
    final totalCost = _calculateTotalCost(quotation, quantity);
    final ratio = baseSelling / baseCost;
    return totalCost * ratio;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show loading indicator while company data is loading
    if (isLoadingCompanyData) {
      return Scaffold(
        appBar: AppBar(title: CustomText(title: "Quotation Table")),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B4513)),
        ),
      );
    }

    List<QuotationItem> allItems = [];

    for (var quotation in widget.selectedQuotations) {
      final quotationId = quotation["id"] as String;
      final quantity = widget.quotationQuantities[quotationId] ?? 1;
      final product = quotation["product"] ?? {};

      // Get the selling price (includes overhead)
      final totalSellingPrice = _calculateTotalSellingPrice(
        quotation,
        quantity,
      );
      final sellingPricePerUnit = quantity > 0
          ? totalSellingPrice / quantity
          : 0.0;

      allItems.add(
        QuotationItem(
          product: product["name"] ?? "Unknown Product",
          description: product["description"] ?? "",
          quantity: quantity,
          unitPrice: "₦${sellingPricePerUnit.toStringAsFixed(2)}",
          total: "₦${totalSellingPrice.toStringAsFixed(2)}",
        ),
      );
    }

    final totalSum = allItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (double.tryParse(item.total.replaceAll(RegExp(r'[₦,]'), '')) ?? 0),
    );

    return Scaffold(
      appBar: AppBar(title: CustomText(title: "Quotation Table")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            children: [
              // ✅ Using company data from SharedPreferences
              QuotationInfo(
                title: "Company Information",
                contact: ContactInfo(
                  name: companyName,
                  address: companyAddress.isNotEmpty 
                      ? companyAddress 
                      : "No address provided",
                  nearestBusStop: companyAddress.isNotEmpty 
                      ? companyAddress 
                      : "No address provided",
                  phone: companyPhone.isNotEmpty 
                      ? companyPhone 
                      : "No phone provided",
                  email: companyEmail.isNotEmpty 
                      ? companyEmail 
                      : "No email provided",
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
                        onPressed: isLoading
                            ? null
                            : () => _saveQuotation(allItems, totalSum),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded(
                    //   child: CustomButton(
                    //     text: "Send to Client",
                    //     onPressed: () {
                    //       // TODO: implement sending functionality
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // CustomButton(
              //   text: "Download PDF",
              //   outlined: true,
              //   onPressed: () {
              //     // TODO: implement PDF download
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuotation(
    List<QuotationItem> allItems,
    double totalSum,
  ) async {
    setState(() => isLoading = true);

    final bomService = BOMService();

    // Flatten materials for backend with selling prices
    final items = widget.selectedQuotations
        .map((quotation) {
          final quotationId = quotation["id"] as String;
          final quantity = widget.quotationQuantities[quotationId] ?? 1;
          final materials = List<Map<String, dynamic>>.from(
            quotation["materials"] ?? [],
          );
          final product = quotation["product"] ?? {};
          final productImage = product["image"] ?? "";

          // Get selling price for this quotation
          final sellingPricePerUnit = _getSellingPrice(quotation);
          final costPricePerUnit = _getCostPrice(quotation);

          return materials.map((m) {
            final materialQty =
                int.tryParse(m["quantity"]?.toString() ?? "1") ?? 1;
            final unitPrice =
                double.tryParse(m["Price"]?.toString() ?? "0") ?? 0;
            final disableIncrement = m["disableIncrement"] == true;
            final totalQuantity = materialQty * (disableIncrement ? 1 : quantity);

            // Calculate proportional selling price for this material
            final materialCostShare = costPricePerUnit > 0
                ? unitPrice / costPricePerUnit
                : 0;
            final materialSellingPrice =
                sellingPricePerUnit * materialCostShare * totalQuantity;

            return {
              "woodType": m["Product"] ?? "",
              "foamType": null,
              "width": double.tryParse(m["Width"]?.toString() ?? "0") ?? 0,
              "height": double.tryParse(m["Height"]?.toString() ?? "0") ?? 0,
              "length": double.tryParse(m["Length"]?.toString() ?? "0") ?? 0,
              "thickness":
                  double.tryParse(m["Thickness"]?.toString() ?? "0") ?? 0,
              "unit": m["Unit"] ?? "cm",
              "squareMeter": double.tryParse(m["Sqm"]?.toString() ?? "0") ?? 0,
              "quantity": totalQuantity,
              "costPrice": unitPrice * totalQuantity,
              "sellingPrice": materialSellingPrice,
              "description": m["Materialname"] ?? "",
              "image": productImage,
            };
          }).toList();
        })
        .expand((e) => e)
        .toList();

    // ✅ Calculate total cost price and overhead from all quotations
    double totalCostPrice = 0;
    double totalOverheadCost = 0;

    // Get duration data from the first quotation (assuming all have same duration)
    int? expectedDurationValue;
    String? expectedPeriod;

    for (var quotation in widget.selectedQuotations) {
      final costPrice = _getCostPrice(quotation);
      final sellingPrice = _getSellingPrice(quotation);

      final quantity =
          widget.quotationQuantities[quotation["id"] as String] ?? 1;

      final adjustedCost = _calculateTotalCost(quotation, quantity);
      final adjustedSelling = _calculateTotalSellingPrice(quotation, quantity);
      totalCostPrice += adjustedCost;
      totalOverheadCost += adjustedSelling - adjustedCost;

      // Get duration data (only from first quotation)
      if (expectedDurationValue == null &&
          quotation.containsKey("expectedDuration")) {
        final durationStr = quotation["expectedDuration"]?.toString();
        expectedDurationValue = int.tryParse(durationStr ?? "24") ?? 24;
      }
      if (expectedPeriod == null && quotation.containsKey("expectedPeriod")) {
        expectedPeriod = quotation["expectedPeriod"]?.toString() ?? "Day";
      }
    }

    final service = {
      "product": "Materials Service",
      "quantity": 1,
      "discount": 0,
      "totalPrice": totalSum,
    };

    // ✅ Call the updated createQuotation method with duration parameters
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
      additionalData: {
        "expectedDuration": expectedDurationValue ?? 24,
        "expectedPeriod": expectedPeriod ?? "Day",
        "costPrice": totalCostPrice,
        "overheadCost": totalOverheadCost,
      },
    );

    setState(() => isLoading = false);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Quotation created successfully")),
      );

      Nav.pop();
      Nav.pop();
      Nav.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: ${response["message"] ?? "Error"}")),
      );
    }
  }
}
