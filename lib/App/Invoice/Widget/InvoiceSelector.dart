// invoice_template_selector.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:wworker/App/Invoice/Widget/DarkInvoice.dart';
import 'package:wworker/App/Invoice/Widget/elegantInvoice.dart';
import 'package:wworker/App/Invoice/Widget/minimalInvoice.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';
import 'dart:io';


class InvoiceTemplateSelector extends StatefulWidget {
  final String clientName;
  final String clientAddress;
  final String clientBusStop;
  final String clientPhone;
  final String clientEmail;
  final String invoiceNumber;
  final String quotationNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String? paymentStatus;
  final String description;
  final List<dynamic> items;
  final double grandTotal;
  final double amountPaid;
  final double balance;
  final bool isExistingInvoice;
  final Future<void> Function(int templateIndex, File pdfFile)? onTemplateSend;
  final int? initialTemplateIndex;
  final bool allowSelection;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String bankCode;

  const InvoiceTemplateSelector({
    super.key,
    required this.clientName,
    required this.clientAddress,
    required this.clientBusStop,
    required this.clientPhone,
    required this.clientEmail,
    required this.invoiceNumber,
    required this.quotationNumber,
    required this.invoiceDate,
    this.dueDate,
    this.paymentStatus,
    required this.description,
    required this.items,
    required this.grandTotal,
    this.amountPaid = 0,
    this.balance = 0,
    this.isExistingInvoice = false,
    this.onTemplateSend,
    this.initialTemplateIndex,
    this.allowSelection = true,
    this.bankName = "Your Bank",
    this.accountName = "Account Name",
    this.accountNumber = "0000000000",
    this.bankCode = "000000",
  });

  @override
  State<InvoiceTemplateSelector> createState() =>
      _InvoiceTemplateSelectorState();
}

class _InvoiceTemplateSelectorState extends State<InvoiceTemplateSelector> {
  int selectedTemplate = 0;
  late final PageController _pageController;
  bool isGeneratingPdf = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  // ✅ Create templates list once, not as a getter
  late final List<Widget> templates;

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplateIndex != null &&
        widget.initialTemplateIndex! >= 0 &&
        widget.initialTemplateIndex! <= 2) {
      selectedTemplate = widget.initialTemplateIndex!;
    }
    _pageController = PageController(initialPage: selectedTemplate);
    // ✅ Initialize templates once in initState
    templates = [
      ModernInvoiceTemplate(
        key: const ValueKey('modern_template'), // ✅ Add unique keys
        clientName: widget.clientName,
        clientAddress: widget.clientAddress,
        clientBusStop: widget.clientBusStop,
        clientPhone: widget.clientPhone,
        clientEmail: widget.clientEmail,
        invoiceNumber: widget.invoiceNumber,
        quotationNumber: widget.quotationNumber,
        invoiceDate: widget.invoiceDate,
        dueDate: widget.dueDate,
        paymentStatus: widget.paymentStatus,
        description: widget.description,
        items: widget.items,
        grandTotal: widget.grandTotal,
        amountPaid: widget.amountPaid,
        balance: widget.balance,
        isExistingInvoice: widget.isExistingInvoice,
        bankName: widget.bankName,
        accountName: widget.accountName,
        accountNumber: widget.accountNumber,
        bankCode: widget.bankCode,
      ),
      MinimalInvoiceTemplate(
        key: const ValueKey('minimal_template'), // ✅ Add unique keys
        clientName: widget.clientName,
        clientAddress: widget.clientAddress,
        clientBusStop: widget.clientBusStop,
        clientPhone: widget.clientPhone,
        clientEmail: widget.clientEmail,
        invoiceNumber: widget.invoiceNumber,
        quotationNumber: widget.quotationNumber,
        invoiceDate: widget.invoiceDate,
        dueDate: widget.dueDate,
        paymentStatus: widget.paymentStatus,
        description: widget.description,
        items: widget.items,
        grandTotal: widget.grandTotal,
        amountPaid: widget.amountPaid,
        balance: widget.balance,
        isExistingInvoice: widget.isExistingInvoice,
        bankName: widget.bankName,
        accountName: widget.accountName,
        accountNumber: widget.accountNumber,
        bankCode: widget.bankCode,
      ),
      ElegantInvoiceTemplate(
        key: const ValueKey('elegant_template'), // ✅ Add unique keys
        clientName: widget.clientName,
        clientAddress: widget.clientAddress,
        clientBusStop: widget.clientBusStop,
        clientPhone: widget.clientPhone,
        clientEmail: widget.clientEmail,
        invoiceNumber: widget.invoiceNumber,
        quotationNumber: widget.quotationNumber,
        invoiceDate: widget.invoiceDate,
        dueDate: widget.dueDate,
        paymentStatus: widget.paymentStatus,
        description: widget.description,
        items: widget.items,
        grandTotal: widget.grandTotal,
        amountPaid: widget.amountPaid,
        balance: widget.balance,
        isExistingInvoice: widget.isExistingInvoice,
        bankName: widget.bankName,
        accountName: widget.accountName,
        accountNumber: widget.accountNumber,
        bankCode: widget.bankCode,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> templateInfo = [
    {
      'name': 'Modern Dark',
      'description': 'Bold dark theme with curved design',
    },
    {
      'name': 'Minimal Clean',
      'description': 'Simple and professional layout',
    },
    {
      'name': 'Elegant Botanical',
      'description': 'Soft colors with natural elements',
    },
  ];

  Future<File> _generatePdfFromTemplate() async {
    try {
      debugPrint("📸 Capturing screenshot of template...");
      
      // Get the template and wrap it properly for PDF capture
      final templateWidget = templates[selectedTemplate];
      
      // Capture the selected template as an image with high resolution
      final imageBytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(1600, 2262), // Double the size for better quality
            devicePixelRatio: 3.0, // High DPI for crisp output
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Container(
                width: 1600, // A4 width * 2
                height: 2262, // A4 height * 2
                color: Colors.white,
                child: templateWidget,
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 500),
        context: context,
        pixelRatio: 3.0, // High pixel ratio for sharp text
      );
      
      debugPrint("✅ Screenshot captured: ${imageBytes.length} bytes");
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Convert screenshot to PDF image
      final image = pw.MemoryImage(imageBytes);
      
      // Add page with the image
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
      
      debugPrint("📄 PDF document created");
      
      // Get temporary directory
      final directory = await path_provider.getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/invoice_${widget.invoiceNumber}_$timestamp.pdf';
      
      // Save PDF to file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      debugPrint("💾 PDF saved to: $filePath");
      
      return file;
    } catch (e) {
      debugPrint("❌ Error in PDF generation: $e");
      rethrow;
    }
  }

  Future<void> _handleSendInvoice() async {
    if (widget.onTemplateSend == null) return;

    setState(() => isGeneratingPdf = true);

    try {
      debugPrint("📄 Starting PDF generation for template $selectedTemplate");
      
      // Generate PDF from selected template
      final pdfFile = await _generatePdfFromTemplate();
      
      debugPrint("✅ PDF generated successfully: ${pdfFile.path}");
      
      // Call the callback with both template index and PDF file
      await widget.onTemplateSend!(selectedTemplate, pdfFile);
      
    } catch (e) {
      debugPrint('❌ Error generating or sending PDF: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Failed to generate PDF: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSelect = widget.allowSelection;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isExistingInvoice
              ? "Invoice Templates"
              : "Choose Invoice Template",
        ),
        centerTitle: true,
        actions: const [
          GuideHelpIcon(
            title: "Invoice Templates",
            message:
                "Browse available invoice layouts and preview how your "
                "invoice will look. In normal flow, your default template "
                "is picked from Settings.",
          ),
        ],
      ),
      body: Column(
        children: [
          if (canSelect)
            // Template selector tabs
            Container(
              height: 80,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: templateInfo.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedTemplate == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedTemplate = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA16438)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFA16438)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            templateInfo[index]['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            templateInfo[index]['description']!,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Template preview
          Expanded(
            child: canSelect
                ? PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => selectedTemplate = index);
                    },
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: templates[index],
                        ),
                      );
                    },
                  )
                : Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: templates[selectedTemplate],
                    ),
                  ),
          ),

          // Action buttons - Only show for new invoices
          if (!widget.isExistingInvoice)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isGeneratingPdf ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFA16438),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: Color(0xFFA16438),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isGeneratingPdf ? null : _handleSendInvoice,
                        icon: isGeneratingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          isGeneratingPdf ? 'Generating...' : 'Send Invoice',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA16438),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
}
