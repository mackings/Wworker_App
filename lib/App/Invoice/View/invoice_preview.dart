import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';
import 'package:wworker/App/Invoice/Widget/InvoiceSelector.dart';
import 'package:wworker/App/Invoice/Widget/invoice_bank_prefs.dart';
import 'package:wworker/App/Invoice/Widget/invoice_template_prefs.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class InvoicePreview extends StatefulWidget {
  final Quotation? quotation;
  final InvoiceModel? invoice;

  const InvoicePreview({super.key, this.quotation, this.invoice})
    : assert(
        quotation != null || invoice != null,
        'Either quotation or invoice must be provided',
      );

  @override
  State<InvoicePreview> createState() => _InvoicePreviewState();
}

class _InvoicePreviewState extends State<InvoicePreview> {
  bool isLoading = false;
  final ClientService _clientService = ClientService();
  int _templateIndex = 0;
  bool _isTemplateLoading = true;
  bool _isBankLoading = true;
  String _bankName = "Your Bank";
  String _accountName = "Account Name";
  String _accountNumber = "0000000000";
  String _bankCode = "000000";

  // Check if viewing existing invoice
  bool get isExistingInvoice => widget.invoice != null;

  // Helper getters to work with both quotation and invoice
  String get clientName =>
      widget.quotation?.clientName ?? widget.invoice!.clientName;
  String get clientAddress =>
      widget.quotation?.clientAddress ?? widget.invoice!.clientAddress;
  String get phoneNumber =>
      widget.quotation?.phoneNumber ?? widget.invoice!.phoneNumber;
  String get email => widget.quotation?.email ?? widget.invoice!.email;
  String get quotationNumber =>
      widget.quotation?.quotationNumber ?? widget.invoice!.quotationNumber;
  String get nearestBusStop =>
      widget.quotation?.nearestBusStop ?? widget.invoice!.nearestBusStop;
  String get description =>
      widget.quotation?.description ?? widget.invoice!.description;

  // Get items based on whether it's a quotation or invoice
  List<dynamic> get items {
    if (widget.quotation != null) {
      return widget.quotation!.items;
    } else {
      return widget.invoice!.items;
    }
  }

  // Grand total from quotation/invoice
  double get grandTotal {
    return widget.quotation?.finalTotal.toDouble() ??
        widget.invoice!.finalTotal;
  }

  @override
  void initState() {
    super.initState();
    _loadTemplateIndex();
    _loadBankDetails();
  }

  Future<void> _loadTemplateIndex() async {
    final index = await InvoiceTemplatePrefs.getTemplateIndex();
    if (!mounted) return;
    setState(() {
      _templateIndex = index;
      _isTemplateLoading = false;
    });
  }

  Future<void> _loadBankDetails() async {
    final details = await InvoiceBankPrefs.getBankDetails();
    if (!mounted) return;
    setState(() {
      _bankName = details["bankName"] ?? _bankName;
      _accountName = details["accountName"] ?? _accountName;
      _accountNumber = details["accountNumber"] ?? _accountNumber;
      _bankCode = details["bankCode"] ?? _bankCode;
      _isBankLoading = false;
    });
  }

  Future<void> _editBankDetails() async {
    final bankNameController = TextEditingController(text: _bankName);
    final accountNameController = TextEditingController(text: _accountName);
    final accountNumberController = TextEditingController(text: _accountNumber);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Bank Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Bank Name",
                  hintText: "Enter bank name",
                  controller: bankNameController,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: "Account Name",
                  hintText: "Enter account name",
                  controller: accountNameController,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: "Account Number",
                  hintText: "Enter account number",
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "Save",
                  onPressed: () async {
                    await InvoiceBankPrefs.saveBankDetails(
                      bankName: bankNameController.text.trim(),
                      accountName: accountNameController.text.trim(),
                      accountNumber: accountNumberController.text.trim(),
                      bankCode: _bankCode,
                    );
                    if (!mounted) return;
                    setState(() {
                      _bankName = bankNameController.text.trim();
                      _accountName = accountNameController.text.trim();
                      _accountNumber = accountNumberController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isExistingInvoice ? "Invoice Details" : "Invoice Preview"),
        elevation: 0,
        actions: const [
          GuideHelpIcon(
            title: "Invoice Preview",
            message:
                "Invoices use your default template from Settings. "
                "You can preview the layout here, then send the invoice when ready.",
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA16438).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    size: 60,
                    color: Color(0xFFA16438),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  isExistingInvoice
                      ? 'View Invoice'
                      : 'Ready to Create Invoice',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF302E2E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  isExistingInvoice
                      ? 'Choose a template to view your invoice'
                      : 'Select a beautiful template for your invoice',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Invoice details card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.person, 'Client', clientName),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.numbers,
                        'Quotation',
                        quotationNumber,
                      ),
                      if (isExistingInvoice) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.receipt,
                          'Invoice No',
                          widget.invoice!.invoiceNumber,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.attach_money,
                        'Amount',
                        '₦${grandTotal.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                if (!_isBankLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Bank Details",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: _editBankDetails,
                              child: const Text("Add Bank Details"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.account_balance,
                          "Bank",
                          _bankName,
                        ),
                        _buildDetailRow(
                          Icons.person_outline,
                          "Account Name",
                          _accountName,
                        ),
                        _buildDetailRow(
                          Icons.numbers,
                          "Account No",
                          _accountNumber,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (isLoading || _isTemplateLoading)
                        ? null
                        : _navigateToTemplateSelector,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.style),
                    label: Text(
                      isExistingInvoice ? 'View Invoice' : 'Preview Invoice',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA16438),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFA16438)),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF302E2E),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _navigateToTemplateSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceTemplateSelector(
          // ✅ Removed all company parameters - templates load from SharedPreferences
          clientName: clientName,
          clientAddress: clientAddress,
          clientBusStop: nearestBusStop,
          clientPhone: phoneNumber,
          clientEmail: email,
          invoiceNumber: isExistingInvoice
              ? widget.invoice!.invoiceNumber
              : "INV-${DateTime.now().millisecondsSinceEpoch}",
          quotationNumber: quotationNumber,
          invoiceDate: isExistingInvoice
              ? widget.invoice!.createdAt
              : DateTime.now(),
          dueDate: isExistingInvoice ? widget.invoice?.dueDate : null,
          paymentStatus: isExistingInvoice
              ? widget.invoice?.paymentStatus
              : null,
          description: description,
          items: items,
          grandTotal: grandTotal,
          amountPaid: isExistingInvoice ? widget.invoice!.amountPaid : 0,
          balance: isExistingInvoice ? widget.invoice!.balance : 0,
          isExistingInvoice: isExistingInvoice,
          onTemplateSend: !isExistingInvoice ? _sendInvoiceToClient : null,
          initialTemplateIndex: _templateIndex,
          allowSelection: false,
          bankName: _bankName,
          accountName: _accountName,
          accountNumber: _accountNumber,
          bankCode: _bankCode,
        ),
      ),
    );
  }

  // Send invoice to client with PDF
  Future<void> _sendInvoiceToClient(int templateIndex, File pdfFile) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => isLoading = true);

    try {
      // Calculate due date (30 days from now)
      final dueDate = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String();

      debugPrint("📤 Sending invoice with PDF: ${pdfFile.path}");
      debugPrint("📋 Template Index: $templateIndex");

      final response = await _clientService.createInvoice(
        quotationId: widget.quotation!.id,
        dueDate: dueDate,
        notes: "Payment due within 30 days. Template: $templateIndex",
        amountPaid: 0,
        pdfFile: pdfFile,
      );

      setState(() => isLoading = false);

      if (response["success"] == true) {
        if (!mounted) return;

        // Clean up temporary PDF file after successful upload
        try {
          if (await pdfFile.exists()) {
            await pdfFile.delete();
            debugPrint("🗑️ Temporary PDF deleted successfully");
          }
        } catch (deleteError) {
          debugPrint("⚠️ Could not delete temp PDF: $deleteError");
        }

        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Invoice created and sent successfully!")),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to the main dashboard (bottom nav home).
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        // Clean up PDF even on failure
        try {
          if (await pdfFile.exists()) {
            await pdfFile.delete();
          }
        } catch (deleteError) {
          debugPrint("⚠️ Could not delete temp PDF: $deleteError");
        }

        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    response["message"] ?? "Failed to create invoice",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      debugPrint("❌ Error sending invoice: $e");

      if (!mounted) return;

      // Attempt to clean up PDF on error
      try {
        if (await pdfFile.exists()) {
          await pdfFile.delete();
          debugPrint("🗑️ Temporary PDF deleted after error");
        }
      } catch (deleteError) {
        debugPrint("⚠️ Could not delete temp PDF: $deleteError");
      }

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Error: ${e.toString()}")),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
