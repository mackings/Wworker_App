import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Widget/QuoInfo.dart';
import 'package:wworker/App/Quotation/Widget/QuoTable.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';

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
  bool isSharing = false;

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

  Future<void> _shareQuotationPdf(
    BuildContext context, {
    required List<QuotationItem> items,
    required double totalSum,
  }) async {
    if (isSharing) return;
    setState(() => isSharing = true);

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFA16438)),
        ),
      );

      final pdf = await _generateQuotationPdf(items: items, totalSum: totalSum);

      if (!mounted) return;
      navigator.pop();

      final directory = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = widget.name
          .trim()
          .replaceAll(RegExp(r'\\s+'), '_')
          .replaceAll(RegExp(r'[^A-Za-z0-9_\\-]'), '');
      final filePath = '${directory.path}/quotation_${safeName}_$ts.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Quotation for ${widget.name}');
    } catch (e) {
      if (mounted) {
        navigator.maybePop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to share quotation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSharing = false);
    }
  }

  Future<pw.Document> _generateQuotationPdf({
    required List<QuotationItem> items,
    required double totalSum,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMM yyyy');

    pw.Widget infoBlock(String title, Map<String, String> rows) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...rows.entries.map(
              (e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 90,
                      child: pw.Text(
                        '${e.key}:',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        e.value,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget tableCell(
      String text, {
      bool header = false,
      pw.TextAlign? align,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          text,
          textAlign: align ?? pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#A16438'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Quotation',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    dateFormat.format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            infoBlock('Company Information', {
              'Name': companyName,
              'Phone': companyPhone.isNotEmpty ? companyPhone : 'N/A',
              'Email': companyEmail.isNotEmpty ? companyEmail : 'N/A',
              'Address': companyAddress.isNotEmpty ? companyAddress : 'N/A',
            }),
            pw.SizedBox(height: 12),
            infoBlock('Client Information', {
              'Name': widget.name,
              'Phone': widget.phone,
              'Email': widget.email,
              'Address': widget.address,
              'Bus stop': widget.nearestBusStop,
            }),
            pw.SizedBox(height: 16),
            pw.Text(
              'Items',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F8F2'),
                  ),
                  children: [
                    tableCell('Product', header: true),
                    tableCell('Desc', header: true),
                    tableCell('Qty', header: true, align: pw.TextAlign.center),
                    tableCell('Price', header: true, align: pw.TextAlign.right),
                    tableCell('Total', header: true, align: pw.TextAlign.right),
                  ],
                ),
                ...items.map((i) {
                  final desc = i.description.trim().isEmpty
                      ? '-'
                      : i.description;
                  return pw.TableRow(
                    children: [
                      tableCell(i.product),
                      tableCell(desc),
                      tableCell(
                        i.quantity.toString(),
                        align: pw.TextAlign.center,
                      ),
                      tableCell(i.unitPrice, align: pw.TextAlign.right),
                      tableCell(i.total, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'Grand Total: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '₦${totalSum.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
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
      final amount = double.tryParse((cost["amount"] ?? "0").toString()) ?? 0.0;
      final disableIncrement = cost["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quantity;
      additionalTotal += amount * multiplier;
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

  double _calculateTotalSellingPrice(
    Map<String, dynamic> quotation,
    int quantity,
  ) {
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
                    Expanded(
                      child: CustomButton(
                        text: isSharing ? "Sharing..." : "Share",
                        icon: Icons.share,
                        outlined: true,
                        onPressed: isSharing || isLoading
                            ? null
                            : () => _shareQuotationPdf(
                                context,
                                items: allItems,
                                totalSum: totalSum,
                              ),
                      ),
                    ),
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
            final totalQuantity =
                materialQty * (disableIncrement ? 1 : quantity);

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

    final firstProduct = widget.selectedQuotations.isNotEmpty
        ? (widget.selectedQuotations.first["product"] ?? {})
        : {};
    final productId =
        firstProduct["productId"] ?? firstProduct["id"] ?? firstProduct["_id"];

    final service = {
      "product": "Materials Service",
      "quantity": 1,
      "discount": 0,
      "totalPrice": totalSum,
      if (productId != null) "productId": productId,
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
        if (productId != null) "productId": productId,
      },
    );

    setState(() => isLoading = false);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Quotation created successfully")),
      );

      Nav.offAll(const DashboardScreen(initialIndex: 1));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: ${response["message"] ?? "Error"}")),
      );
    }
  }
}
