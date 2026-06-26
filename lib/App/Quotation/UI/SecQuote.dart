import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wworker/App/Invoice/View/invoice_preview.dart';
import 'package:wworker/App/Quotation/Api/BomService.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart' as client_q;
import 'package:wworker/App/Quotation/Providers/MaterialProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuoteSProvider.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/Widget/QuoInfo.dart';
import 'package:wworker/App/Quotation/Widget/QuoTable.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
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
  static const Color _pageBg = Color(0xFFFAF7F3);
  static const Color _ink = Color(0xFF211D1A);
  static const Color _brand = Color(0xFF8B4513);

  bool isLoading = false;
  bool isSharing = false;
  final NumberFormat _currency = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

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
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

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
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
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
                      _currency.format(totalSum),
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
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }

  int _toQuantity(dynamic value) {
    if (value is int) return value < 1 ? 1 : value;
    if (value is num) return value < 1 ? 1 : value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '') ?? 1;
    return parsed < 1 ? 1 : parsed;
  }

  double _materialLineTotal(Map<String, dynamic> item) {
    final calculation = item["calculation"];
    if (calculation is Map) {
      final total = _toDouble(calculation["totalMaterialCost"]);
      if (total != null) return total;
    }

    final storedTotal = _toDouble(item["LineTotal"] ?? item["subtotal"]);
    if (storedTotal != null) return storedTotal;

    final unitPrice = _toDouble(item["unitPrice"]);
    if (unitPrice != null) return unitPrice * _toQuantity(item["quantity"]);

    return _toDouble(item["Price"]) ?? 0.0;
  }

  double _partsCostTotal(
    List<Map<String, dynamic>> materials,
    List<Map<String, dynamic>> additionalCosts,
  ) {
    final materialCost = materials.fold<double>(
      0,
      (sum, m) => sum + _materialLineTotal(m),
    );
    final additionalCost = additionalCosts.fold<double>(
      0,
      (sum, c) => sum + (_toDouble(c["amount"]) ?? 0.0),
    );
    return materialCost + additionalCost;
  }

  double _savedCostPrice(Map<String, dynamic> quotation) {
    return _toDouble(quotation["costPrice"]) ?? 0.0;
  }

  double _savedSellingPrice(Map<String, dynamic> quotation) {
    return _toDouble(quotation["sellingPrice"]) ?? 0.0;
  }

  double _getCostPrice(Map<String, dynamic> quotation) {
    final savedCost = _savedCostPrice(quotation);
    if (savedCost > 0) return savedCost;

    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );
    return _partsCostTotal(materials, additionalCosts);
  }

  // ✅ Get selling price from quotation (cost + overhead)
  double _getSellingPrice(Map<String, dynamic> quotation) {
    final savedSelling = _savedSellingPrice(quotation);
    if (savedSelling > 0) return savedSelling;

    // Fallback to cost price for backward compatibility
    return _getCostPrice(quotation);
  }

  double _calculateTotalCost(Map<String, dynamic> quotation, int quantity) {
    final savedCost = _savedCostPrice(quotation);
    if (savedCost > 0) return savedCost * quantity;

    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );

    double materialTotal = 0.0;
    int disabledCount = 0;
    for (final material in materials) {
      final lineTotal = _materialLineTotal(material);
      final disableIncrement = material["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quantity;
      if (disableIncrement) disabledCount += 1;
      materialTotal += lineTotal * multiplier;
    }

    double additionalTotal = 0.0;
    for (final cost in additionalCosts) {
      final amount = _toDouble(cost["amount"]) ?? 0.0;
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
    final savedSelling = _savedSellingPrice(quotation);
    if (savedSelling > 0) return savedSelling * quantity;

    final baseCost = _getCostPrice(quotation);
    final baseSelling = _getSellingPrice(quotation);
    if (baseCost <= 0) return 0.0;
    final totalCost = _calculateTotalCost(quotation, quantity);
    final ratio = baseSelling / baseCost;
    return totalCost * ratio;
  }

  List<Map<String, dynamic>> _normalizedBomMaterials(
    List<Map<String, dynamic>> materials,
    int quotationQuantity,
  ) {
    return materials.map((material) {
      final materialQuantity = _toQuantity(material["quantity"]);
      final lineTotal = _materialLineTotal(material);
      final disableIncrement = material["disableIncrement"] == true;
      final quoteMultiplier = disableIncrement ? 1 : quotationQuantity;
      final totalQuantity = materialQuantity * quoteMultiplier;
      final subtotal = lineTotal * quoteMultiplier;
      final unitPrice = materialQuantity > 0
          ? lineTotal / materialQuantity
          : lineTotal;

      return {
        "name":
            material["Materialname"] ??
            material["name"] ??
            material["Product"] ??
            "Material",
        "woodType": material["Product"] ?? material["woodType"],
        "foamType": material["foamType"],
        "type": material["type"],
        "width": _toDouble(material["Width"] ?? material["width"]) ?? 0,
        "height": _toDouble(material["Height"] ?? material["height"]) ?? 0,
        "length": _toDouble(material["Length"] ?? material["length"]) ?? 0,
        "thickness":
            _toDouble(material["Thickness"] ?? material["thickness"]) ?? 0,
        "unit": material["Unit"] ?? material["unit"] ?? "unit",
        "squareMeter":
            _toDouble(material["Sqm"] ?? material["squareMeter"]) ?? 0,
        "price": unitPrice,
        "quantity": totalQuantity,
        "subtotal": subtotal,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _normalizedAdditionalCosts(
    List<Map<String, dynamic>> additionalCosts,
    int quotationQuantity,
  ) {
    return additionalCosts.map((cost) {
      final disableIncrement = cost["disableIncrement"] == true;
      final multiplier = disableIncrement ? 1 : quotationQuantity;
      final amount = (_toDouble(cost["amount"]) ?? 0.0) * multiplier;

      return {
        "name": cost["name"] ?? "Additional cost",
        "amount": amount,
        "description": cost["description"] ?? "",
      };
    }).toList();
  }

  Map<String, dynamic> _buildBomPayload(
    Map<String, dynamic> quotation,
    int quantity,
  ) {
    final product = Map<String, dynamic>.from(quotation["product"] ?? {});
    final materials = List<Map<String, dynamic>>.from(
      quotation["materials"] ?? [],
    );
    final additionalCosts = List<Map<String, dynamic>>.from(
      quotation["additionalCosts"] ?? [],
    );
    final normalizedMaterials = _normalizedBomMaterials(materials, quantity);
    final normalizedAdditionalCosts = _normalizedAdditionalCosts(
      additionalCosts,
      quantity,
    );
    final totalCost = _calculateTotalCost(quotation, quantity);
    final sellingPrice = _calculateTotalSellingPrice(quotation, quantity);
    final costPrice = _getCostPrice(quotation) * quantity;
    final quotationId = quotation["id"]?.toString() ?? '';

    return {
      if (quotationId.isNotEmpty) "bomId": quotationId,
      "bomNumber": quotation["bomNumber"]?.toString() ?? quotationId,
      "name": product["name"]?.toString() ?? "BOM",
      "description": product["description"]?.toString() ?? "",
      "productId": product["productId"] ?? product["id"] ?? product["_id"],
      "product": {
        "productId": product["productId"] ?? product["id"] ?? product["_id"],
        "name": product["name"] ?? "Product",
        "description": product["description"] ?? "",
        "image": product["image"] ?? "",
      },
      "materials": normalizedMaterials,
      "additionalCosts": normalizedAdditionalCosts,
      "materialsCost": totalCost,
      "additionalCostsTotal": normalizedAdditionalCosts.fold<double>(
        0,
        (sum, cost) => sum + (_toDouble(cost["amount"]) ?? 0.0),
      ),
      "totalCost": totalCost,
      "pricing": {
        "pricingMethod": quotation["pricingMethod"] ?? "",
        "markupPercentage": _toDouble(quotation["markupPercentage"]) ?? 0.0,
        "materialsTotal": totalCost,
        "additionalTotal": 0,
        "overheadCost": _toDouble(quotation["overheadCost"]) ?? 0.0,
        "costPrice": costPrice,
        "sellingPrice": sellingPrice,
      },
      "expectedDuration": {
        "value": int.tryParse(quotation["expectedDuration"]?.toString() ?? ""),
        "unit": quotation["expectedPeriod"]?.toString() ?? "Day",
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show loading indicator while company data is loading
    if (isLoadingCompanyData) {
      return Scaffold(
        backgroundColor: _pageBg,
        appBar: _buildModernAppBar(),
        body: const Center(child: CircularProgressIndicator(color: _brand)),
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
          unitPrice: _currency.format(sellingPricePerUnit),
          total: _currency.format(totalSellingPrice),
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
      backgroundColor: _pageBg,
      appBar: _buildModernAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).padding.bottom + 24,
          ),
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
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              QuotationTable(items: allItems),

              const SizedBox(height: 16),
              _buildActionRow(allItems: allItems, totalSum: totalSum),
              const SizedBox(height: 10),
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

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: _pageBg,
      surfaceTintColor: _pageBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _ink,
          size: 20,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        "Quotation Table",
        style: TextStyle(
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required List<QuotationItem> allItems,
    required double totalSum,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            text: isLoading ? "Saving..." : "Save",
            icon: isLoading ? null : Icons.save_outlined,
            onPressed: isLoading
                ? null
                : () => _saveQuotation(allItems, totalSum),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            text: isSharing ? "Sharing..." : "Share",
            icon: Icons.share_outlined,
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
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool outlined = false,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 7)],
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return SizedBox(
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _brand,
                side: const BorderSide(color: _brand, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB7835E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFB7835E,
                ).withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              child: child,
            ),
    );
  }

  Future<void> _saveQuotation(
    List<QuotationItem> allItems,
    double totalSum,
  ) async {
    setState(() => isLoading = true);

    final bomService = BOMService();
    final boms = widget.selectedQuotations.map((quotation) {
      final quotationId = quotation["id"] as String;
      final quantity = widget.quotationQuantities[quotationId] ?? 1;
      return _buildBomPayload(quotation, quantity);
    }).toList();

    final items = widget.selectedQuotations.map((quotation) {
      final quotationId = quotation["id"] as String;
      final quantity = widget.quotationQuantities[quotationId] ?? 1;
      final product = Map<String, dynamic>.from(quotation["product"] ?? {});
      final totalCost = _calculateTotalCost(quotation, quantity);
      final totalSellingPrice = _calculateTotalSellingPrice(
        quotation,
        quantity,
      );

      return {
        "woodType": product["name"] ?? "BOM",
        "foamType": null,
        "width": 0,
        "height": 0,
        "length": 0,
        "thickness": 0,
        "unit": "unit",
        "squareMeter": 0,
        "quantity": quantity,
        "costPrice": totalCost,
        "sellingPrice": totalSellingPrice,
        "description": product["description"] ?? "",
        "image": product["image"] ?? "",
      };
    }).toList();

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
    final serviceProduct = widget.selectedQuotations
        .map((quotation) {
          final product = Map<String, dynamic>.from(quotation["product"] ?? {});
          return product["name"]?.toString().trim() ?? "";
        })
        .where((name) => name.isNotEmpty)
        .join(", ");

    final service = {
      "product": serviceProduct.isNotEmpty ? serviceProduct : "BOM",
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
        "boms": boms,
        "expectedDuration": expectedDurationValue ?? 24,
        "expectedPeriod": expectedPeriod ?? "Day",
        "costPrice": totalCostPrice,
        "overheadCost": totalOverheadCost,
        if (productId != null) "productId": productId,
      },
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["success"] == true) {
      final usedQuotationIds = widget.selectedQuotations
          .map((quotation) => quotation["id"]?.toString() ?? "")
          .where((id) => id.isNotEmpty);

      await ref.read(materialProvider.notifier).clearAll();
      final quotationNotifier = ref.read(quotationSummaryProvider.notifier);
      await quotationNotifier.deleteQuotationsByIds(usedQuotationIds);
      await quotationNotifier.clearAll();
      final createdQuotation = _createdQuotationFromResponse(response);
      await _showInvoiceSuggestion(createdQuotation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: ${response["message"] ?? "Error"}")),
      );
    }
  }

  client_q.Quotation? _createdQuotationFromResponse(
    Map<String, dynamic> response,
  ) {
    final payload = _extractQuotationPayload(response["data"]);
    if (payload == null) return null;

    try {
      return client_q.Quotation.fromJson(payload);
    } catch (e) {
      debugPrint("Could not parse created quotation: $e");
      return null;
    }
  }

  Map<String, dynamic>? _extractQuotationPayload(dynamic value) {
    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);
    final hasQuotationShape =
        map.containsKey("_id") ||
        map.containsKey("quotationNumber") ||
        map.containsKey("clientName");
    if (hasQuotationShape) return map;

    for (final key in const ["quotation", "quote", "data"]) {
      final nested = _extractQuotationPayload(map[key]);
      if (nested != null) return nested;
    }

    return null;
  }

  Future<void> _showInvoiceSuggestion(client_q.Quotation? quotation) async {
    if (!mounted) return;

    final goToInvoice = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA16438).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFFA16438),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Create invoice now?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF302E2E),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: "Back to quotations",
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "The quotation has been saved. You can continue straight to the invoice flow for this client.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "Continue to Invoice",
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    Nav.offAll(const DashboardScreen(initialIndex: 1));

    if (goToInvoice == true) {
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (quotation != null) {
          Nav.push(InvoicePreview(quotation: quotation));
        } else {
          Nav.push(
            AllClientQuotations(isForInvoice: true, clientName: widget.name),
          );
        }
      });
    }
  }
}
