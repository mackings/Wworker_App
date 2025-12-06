import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';
import 'package:wworker/App/Invoice/Widget/InvoiceSelector.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';




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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isExistingInvoice ? "Invoice Details" : "Invoice Preview"),
        elevation: 0,
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
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
                      _buildDetailRow(
                        Icons.person,
                        'Client',
                        clientName,
                      ),
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

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _navigateToTemplateSelector,
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
                      isExistingInvoice
                          ? 'View Templates'
                          : 'Choose Template',
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
          companyName: "Sumit Nova Trust Ltd",
          companyAddress: "K3, plaza, New Garage, Ibadan",
          companyBusStop: "Alao Akala Expressway",
          companyPhone: "07034567890",
          companyEmail: "admin@sumitnovatrustltd.com",
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
          paymentStatus: isExistingInvoice ? widget.invoice?.paymentStatus : null,
          description: description,
          items: items,
          grandTotal: grandTotal,
          amountPaid: isExistingInvoice ? widget.invoice!.amountPaid : 0,
          balance: isExistingInvoice ? widget.invoice!.balance : 0,
          isExistingInvoice: isExistingInvoice,
          onTemplateSend: !isExistingInvoice ? _sendInvoiceToClient : null,
        ),
      ),
    );
  }

  Future<void> _sendInvoiceToClient(int templateIndex) async {
    setState(() => isLoading = true);

    try {
      // Calculate due date (30 days from now)
      final dueDate = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String();

      final response = await _clientService.createInvoice(
        quotationId: widget.quotation!.id,
        dueDate: dueDate,
        notes: "Payment due within 30 days. Template: $templateIndex",
        amountPaid: 0,
      );

      setState(() => isLoading = false);

      if (response["success"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Invoice created successfully")),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to home
        Navigator.pop(context); // Close template selector
        Navigator.pop(context); // Close preview
        Navigator.pop(context); // Close quotation details
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ ${response["message"] ?? "Failed to create invoice"}",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
