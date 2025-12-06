// invoice_template_selector.dart
import 'package:flutter/material.dart';
import 'package:wworker/App/Invoice/Widget/DarkInvoice.dart';
import 'package:wworker/App/Invoice/Widget/elegantInvoice.dart';
import 'package:wworker/App/Invoice/Widget/minimalInvoice.dart';


class InvoiceTemplateSelector extends StatefulWidget {
  final String companyName;
  final String companyAddress;
  final String companyBusStop;
  final String companyPhone;
  final String companyEmail;
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
  final Function(int templateIndex)? onTemplateSend;

  const InvoiceTemplateSelector({
    super.key,
    required this.companyName,
    required this.companyAddress,
    required this.companyBusStop,
    required this.companyPhone,
    required this.companyEmail,
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
  });

  @override
  State<InvoiceTemplateSelector> createState() =>
      _InvoiceTemplateSelectorState();
}

class _InvoiceTemplateSelectorState extends State<InvoiceTemplateSelector> {
  int selectedTemplate = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> get templates => [
        ModernInvoiceTemplate(
          companyName: widget.companyName,
          companyAddress: widget.companyAddress,
          companyBusStop: widget.companyBusStop,
          companyPhone: widget.companyPhone,
          companyEmail: widget.companyEmail,
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
        ),
        MinimalInvoiceTemplate(
          companyName: widget.companyName,
          companyAddress: widget.companyAddress,
          companyBusStop: widget.companyBusStop,
          companyPhone: widget.companyPhone,
          companyEmail: widget.companyEmail,
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
        ),
        ElegantInvoiceTemplate(
          companyName: widget.companyName,
          companyAddress: widget.companyAddress,
          companyBusStop: widget.companyBusStop,
          companyPhone: widget.companyPhone,
          companyEmail: widget.companyEmail,
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
        ),
      ];

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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Column(
        children: [
          // Template selector tabs
          Container(
            height: 80,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            color: isSelected ? Colors.white : Colors.black87,
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

          // Template preview - Fixed with proper constraints
          Expanded(
            child: PageView.builder(
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
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () {
                          if (widget.onTemplateSend != null) {
                            widget.onTemplateSend!(selectedTemplate);
                          }
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Send Invoice'),
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