import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Api/client_service.dart';
import 'package:wworker/App/Invoice/Model/invoiceModel.dart';
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

  // ✅ Grand total from quotation/invoice (already includes everything)
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Information
              _buildInfoSection(
                title: "Company Information",
                content: ContactInfo(
                  name: "Sumit Nova Trust Ltd",
                  address: "K3, plaza, New Garage, Ibadan.",
                  nearestBusStop: "Alao Akala Expressway",
                  phone: "07034567890",
                  email: "admin@sumitnovatrustltd.com",
                ),
              ),
              const SizedBox(height: 24),

              // Client Information
              _buildInfoSection(
                title: "Client Information",
                content: ContactInfo(
                  name: clientName,
                  address: clientAddress,
                  nearestBusStop: nearestBusStop,
                  phone: phoneNumber,
                  email: email,
                ),
              ),
              const SizedBox(height: 24),

              // Invoice Details
              _buildInvoiceDetails(),
              const SizedBox(height: 24),

              // Description
              if (description.isNotEmpty) ...[
                _buildDescriptionSection(),
                const SizedBox(height: 24),
              ],

              // Items Table (Products only - no service row)
              _buildItemsTable(),
              const SizedBox(height: 24),

              // Financial Summary (Grand Total only)
              _buildFinancialSummary(),
              const SizedBox(height: 32),

              // Action Buttons - Only show for new invoices from quotations
              if (!isExistingInvoice)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendInvoiceToClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA16438),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text(
                                "Send Invoice to Client",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required ContactInfo content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF302E2E),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Name", content.name),
          _buildInfoRow("Address", content.address),
          if (content.nearestBusStop.isNotEmpty)
            _buildInfoRow("Nearest Bus Stop", content.nearestBusStop),
          _buildInfoRow("Phone", content.phone),
          _buildInfoRow("Email", content.email),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA16438).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Project Description",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA16438),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Color(0xFF302E2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF302E2E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA16438), width: 2),
      ),
      child: Column(
        children: [
          // Show invoice number for existing invoices
          if (isExistingInvoice) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Invoice No:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B7B7B),
                  ),
                ),
                Text(
                  widget.invoice!.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA16438),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Quotation number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quotation No:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7B7B7B),
                ),
              ),
              Text(
                quotationNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA16438),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExistingInvoice ? "Created Date:" : "Invoice Date:",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7B7B7B),
                ),
              ),
              Text(
                _formatDate(widget.invoice?.createdAt ?? DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF302E2E),
                ),
              ),
            ],
          ),

          // Due date for existing invoices
          if (isExistingInvoice && widget.invoice!.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Due Date:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B7B7B),
                  ),
                ),
                Text(
                  _formatDate(widget.invoice!.dueDate!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF302E2E),
                  ),
                ),
              ],
            ),
          ],

          // Payment status for existing invoices
          if (isExistingInvoice) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Payment Status:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B7B7B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.invoice!.paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.invoice!.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.invoice!.paymentStatus),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildItemsTable() {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No Items Found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFA16438),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Qty",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Price",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items (Products only - NO service row)
          ...items.map((item) {
            final invoiceItem = item as dynamic;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoiceItem.woodType ??
                              invoiceItem.foamType ??
                              "Material",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF302E2E),
                          ),
                        ),
                        if (invoiceItem.description?.isNotEmpty ?? false)
                          Text(
                            invoiceItem.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        // Show dimensions for invoice items
                        if (isExistingInvoice)
                          Text(
                            "${invoiceItem.width} × ${invoiceItem.length} × ${invoiceItem.thickness} ${invoiceItem.unit}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${invoiceItem.quantity}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "₦${grandTotal.toStringAsFixed(2)}",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          // ❌ REMOVED: Service row completely
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // ✅ SIMPLIFIED: Only show Grand Total
          _buildSummaryRow(
            "Grand Total",
            "₦${grandTotal.toStringAsFixed(2)}",
            isBold: true,
            isGrandTotal: true,
          ),

          // Show payment details for existing invoices
          if (isExistingInvoice) ...[
            const SizedBox(height: 16),
            const Divider(height: 8, thickness: 2),
            const SizedBox(height: 16),
            _buildSummaryRow(
              "Amount Paid",
              "₦${widget.invoice!.amountPaid.toStringAsFixed(2)}",
              isPaid: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              "Outstanding Balance",
              "₦${widget.invoice!.balance.toStringAsFixed(2)}",
              isBold: true,
              isBalance: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isGrandTotal = false,
    bool isDiscount = false,
    bool isPaid = false,
    bool isBalance = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isGrandTotal || isBalance
                  ? const Color(0xFFA16438)
                  : const Color(0xFF302E2E),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDiscount
                  ? Colors.red
                  : isPaid
                  ? Colors.green
                  : isGrandTotal || isBalance
                  ? const Color(0xFFA16438)
                  : const Color(0xFF302E2E),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _sendInvoiceToClient() async {
    setState(() => isLoading = true);

    try {
      // Calculate due date (30 days from now)
      final dueDate = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String();

      final response = await _clientService.createInvoice(
        quotationId: widget.quotation!.id,
        dueDate: dueDate,
        notes: "Payment due within 30 days",
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
                Expanded(child: Text("✅ Invoice created successfully")),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to home or invoice list
        Navigator.pop(context);
        Navigator.pop(context);
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
}

// ContactInfo model
class ContactInfo {
  final String name;
  final String address;
  final String nearestBusStop;
  final String phone;
  final String email;

  ContactInfo({
    required this.name,
    required this.address,
    required this.nearestBusStop,
    required this.phone,
    required this.email,
  });
}